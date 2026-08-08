#!/usr/bin/env python3
"""Structural checks for the Docker Sandbox Pi launcher.

The launcher keeps lifecycle and ownership state in bash; every check that needs
real parsing lives here so neither language carries the other's logic. Each
subcommand fails closed — it exits non-zero with a diagnostic on stderr rather
than degrading to a weaker guarantee.

Subcommands that inspect `sbx` output read it from standard input.
"""

from __future__ import annotations

import ipaddress
import json
import os
import re
import stat
import subprocess
import sys
from pathlib import PurePosixPath
from typing import NoReturn

PROHIBITED_BASENAMES = {".npmrc", "auth.json", "id_rsa", "id_ed25519"}
PROHIBITED_PARTS = {"node_modules", ".venv"}
PROHIBITED_PART_PAIRS = {(".pi", "npm"), (".pi", "git")}
NETWORK_RESOURCE_TYPES = {"network", "net:domain", "net:ip"}
HOSTNAME = re.compile(r"(?=.{1,253}$)(?!-)(?:[A-Za-z0-9-]{1,63}\.)*[A-Za-z0-9-]{1,63}")


def die(message: str) -> NoReturn:
    raise SystemExit(f"sandbox contract: {message}")


def read_inventory() -> list[dict]:
    return json.load(sys.stdin).get("sandboxes", [])


def read_rules() -> list[dict]:
    return json.load(sys.stdin).get("rules", [])


def split_csv(value: str) -> set[str]:
    return set(filter(None, value.split(",")))


def cmd_sandbox_present(name: str) -> int:
    """Exit 0 when the named sandbox appears in the inventory."""
    return 0 if any(item.get("name") == name for item in read_inventory()) else 1


def cmd_sandbox_identity(name: str, workspaces_file: str, expected_id: str = "") -> int:
    """Assert the sandbox matches its recorded creation contract; print its ID.

    `workspaces_file` holds one expected workspace per line, written exactly as
    it was passed to `sbx create` — including any `:ro` suffix, which `sbx ls`
    echoes back verbatim.
    """
    items = [item for item in read_inventory() if item.get("name") == name]
    if len(items) != 1:
        die("named sandbox is absent or duplicated")
    item = items[0]
    if item.get("agent") != "shell" or not item.get("id"):
        die("sandbox identity or agent contract mismatch")
    if expected_id and item.get("id") != expected_id:
        die("sandbox identity or agent contract mismatch")
    with open(workspaces_file, encoding="utf-8") as handle:
        expected = sorted(line.rstrip("\n") for line in handle if line.rstrip("\n"))
    if sorted(item.get("workspaces", [])) != expected:
        die(
            "sandbox workspace contract mismatch\n"
            f"  expected: {expected}\n"
            f"  reported: {sorted(item.get('workspaces', []))}"
        )
    print(item["id"])
    return 0


def cmd_policy_rule_absent(rule_id: str) -> int:
    """Exit 0 when the rule ID is absent from the sandbox-scoped inventory."""
    return 0 if all(rule.get("id") != rule_id for rule in read_rules()) else 1


def cmd_policy_effective(
    acknowledged_csv: str, owned_ids_csv: str, owned_resources_csv: str
) -> int:
    """Reject any active network allow that is neither owned nor acknowledged.

    Acknowledged rules are template-supplied and permitted, not required: a
    template that ships no rule of its own is still valid. Prints the
    acknowledged resources actually observed, one per line, so the caller can
    positively check exactly those.
    """
    acknowledged = split_csv(acknowledged_csv)
    owned_ids = split_csv(owned_ids_csv)
    owned_resources = split_csv(owned_resources_csv)
    seen: set[str] = set()

    for rule in read_rules():
        if rule.get("status") != "active" or rule.get("decision") != "allow":
            continue
        if rule.get("resource_type") not in NETWORK_RESOURCE_TYPES:
            continue
        for raw in rule.get("resources", []):
            if "*" in raw:
                die(f"broad active network allow is unsupported: {raw}")
            normalized = raw if ":" in raw else f"{raw}:443"
            if rule.get("id") in owned_ids:
                if not rule.get("editable") or raw not in owned_resources:
                    die(f"invocation policy does not match its ownership contract: {raw}")
            elif normalized in acknowledged:
                seen.add(normalized)
            else:
                die(f"unapproved active network allow is unsupported: {raw}")

    for resource in sorted(seen):
        print(resource)
    return 0


def cmd_clean_source(root_argument: str) -> int:
    """Reject a generated clone that carries anything unsafe to send to a VM."""
    root = os.path.realpath(root_argument)
    entries = subprocess.check_output(["git", "-C", root, "ls-files", "-s", "-z"]).split(b"\0")
    for raw in filter(None, entries):
        metadata, encoded_path = raw.split(b"\t", 1)
        mode = metadata.split(b" ", 1)[0]
        path = encoded_path.decode("utf-8", "surrogateescape")
        if mode in {b"120000", b"160000"}:
            die(f"prohibited symlink or submodule: {path}")
        if any(ord(character) < 32 for character in path):
            die("control characters are prohibited in tracked source paths")
        pure = PurePosixPath(path)
        if pure.is_absolute() or ".." in pure.parts:
            die(f"prohibited path escape: {path}")
        candidate = os.path.realpath(os.path.join(root, path))
        if os.path.commonpath([root, candidate]) != root:
            die(f"prohibited canonical path escape: {path}")
        if path == ".env.example":
            continue
        parts = pure.parts
        prohibited = (
            any(part == ".env" or part.startswith(".env.") for part in parts)
            or pure.name in PROHIBITED_BASENAMES
            or any(part in PROHIBITED_PARTS for part in parts)
            or any(
                parts[index : index + 2] in PROHIBITED_PART_PAIRS
                for index in range(len(parts) - 1)
            )
            or pure.name.endswith((".pem", ".key"))
        )
        if prohibited:
            die(f"prohibited tracked source path: {path}")
    return 0


def cmd_snapshot_settings(source: str, destination: str) -> int:
    """Copy user settings byte-for-byte into an invocation-owned snapshot.

    Opened with O_NOFOLLOW and re-checked through fstat so a symlink or a
    path swapped between validation and read cannot redirect the copy. A
    top-level legacy `apiKeys` field is rejected without printing any value.
    """
    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
    fd = os.open(source, flags)
    try:
        if not stat.S_ISREG(os.fstat(fd).st_mode):
            die("user settings must remain a regular file")
        with os.fdopen(fd, "rb", closefd=False) as handle:
            payload = handle.read()
        value = json.loads(payload.decode("utf-8"))
        if isinstance(value, dict) and "apiKeys" in value:
            die("top-level legacy apiKeys is not permitted")
        output_fd = os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o400)
        try:
            os.write(output_fd, payload)
            os.fsync(output_fd)
        finally:
            os.close(output_fd)
    finally:
        os.close(fd)
    return 0


def cmd_validate_network(label: str, *resources: str) -> int:
    """Require exact non-wildcard host:port destinations."""
    for resource in resources:
        if not resource or "*" in resource or resource != resource.strip():
            die(f"{label} must contain exact non-wildcard host:port resources")
        host, separator, port = resource.rpartition(":")
        if not separator or not host or not port.isdigit() or not 1 <= int(port) <= 65535:
            die(f"{label} must contain exact non-wildcard host:port resources")
        try:
            ipaddress.ip_address(host.strip("[]"))
        except ValueError:
            if not HOSTNAME.fullmatch(host):
                die(f"{label} contains an invalid host")
    return 0


def cmd_registry_secret_absent() -> int:
    """Prove no global registry credential could contaminate the sandbox.

    Reads `sbx secret ls --global` output by name and scope only; values are
    never parsed or printed.
    """
    lines = [line for line in sys.stdin.read().splitlines() if line.strip()]
    header = lines[0] if lines else ""
    if not lines or not all(column in header for column in ("SCOPE", "TYPE", "NAME")):
        die("global credential inventory could not prove registry credential absence")
    for line in lines[1:]:
        fields = line.split()
        if len(fields) >= 2 and fields[1] == "registry":
            die("global registry credential contamination is unsupported")
    return 0


COMMANDS = {
    "sandbox-present": cmd_sandbox_present,
    "sandbox-identity": cmd_sandbox_identity,
    "policy-rule-absent": cmd_policy_rule_absent,
    "policy-effective": cmd_policy_effective,
    "clean-source": cmd_clean_source,
    "snapshot-settings": cmd_snapshot_settings,
    "validate-network": cmd_validate_network,
    "registry-secret-absent": cmd_registry_secret_absent,
}


def main(argv: list[str]) -> int:
    if not argv or argv[0] not in COMMANDS:
        die(f"usage: sandbox_contract.py {{{'|'.join(COMMANDS)}}} [ARGS...]")
    try:
        return COMMANDS[argv[0]](*argv[1:])
    except TypeError as error:
        die(f"{argv[0]}: {error}")


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
