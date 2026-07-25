#!/usr/bin/env bash
set -euo pipefail

fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT

slug='2099_01_01_0000-lifecycle-fixture'
plan="$fixture/docs/prompts/$slug/README.md"
chain="$fixture/.pi/chains/saved-plans/$slug.chain.json"
index="$fixture/docs/prompts/README.md"
execution="$fixture/chain-executed"
chain_link="../../../.pi/chains/saved-plans/$slug.chain.json"

mkdir -p "$(dirname "$plan")" "$(dirname "$chain")"

cat >"$plan" <<EOF
---
status: draft
---
# Fixture

## Goal

Verify the lifecycle.

## Workflow

[Matching chain]($chain_link)

## Steps

- [ ] Fixture step
EOF

cat >"$chain" <<EOF
{"name":"saved-plan-$slug","description":"Plan-specific execution chain for docs/prompts/$slug/README.md. Run only after explicit user approval and plan-index registration.","chain":[{"agent":"scout","task":"Controlled lifecycle fixture: report that the approved and registered fixture chain executed. Do not modify any files.","output":"fixture-result.md","outputMode":"inline"}]}
EOF

cat >"$index" <<'EOF'
# Plans

| Plan | Status | Description |
| --- | --- | --- |
EOF

validate_pair() {
	grep -Fq "$chain_link" "$plan" || return 1
	[ -f "$(dirname "$plan")/$chain_link" ] || return 1
	jq -e --arg slug "$slug" --arg plan "docs/prompts/$slug/README.md" \
		'.name == "saved-plan-" + $slug and (.description | contains($plan))' "$chain" >/dev/null
}

record_draft() {
	grep -qx 'status: draft' "$plan" || return 1
	validate_pair || return 1

	local count
	count=$(grep -c "| \[$slug\]($slug/README.md)" "$index" || true)
	if [ "$count" -eq 0 ]; then
		printf '| [%s](%s/README.md) | 📝 draft | Fixture |\n' "$slug" "$slug" >>"$index"
	fi

	[ "$(grep -c "| \[$slug\]($slug/README.md)" "$index")" -eq 1 ] || return 1
	grep -F "| [$slug]($slug/README.md)" "$index" | grep -Fq '📝 draft'
}

save_approved() {
	grep -qx 'status: approved' "$plan" || return 1
	validate_pair || return 1
	[ "$(grep -c "| \[$slug\]($slug/README.md)" "$index")" -eq 1 ] || return 1
	grep -F "| [$slug]($slug/README.md)" "$index" | grep -Fq '📝 draft' || return 1

	sed -i.bak 's/| 📝 draft |/| ⬜ not started |/' "$index"
	rm "$index.bak"
	grep -F "| [$slug]($slug/README.md)" "$index" | grep -Fq '⬜ not started'
}

start_chain() {
	grep -qx 'status: approved' "$plan"
	grep -F "| [$slug]($slug/README.md)" "$index" | grep -Fq '⬜ not started'
	: >"$execution"
}

# Registration rejects an approved but unregistered plan and does not execute it.
sed -i.bak 's/status: draft/status: approved/' "$plan"
rm "$plan.bak"
if save_approved >/dev/null 2>&1; then
	echo 'unregistered fixture registered' >&2
	exit 1
fi
[ ! -e "$execution" ]
sed -i.bak 's/status: approved/status: draft/' "$plan"
rm "$plan.bak"

# Draft recording is idempotent and rejects a duplicate lifecycle row.
record_draft
record_draft
printf '| [%s](%s/README.md) | 📝 draft | Duplicate fixture |\n' "$slug" "$slug" >>"$index"
if record_draft >/dev/null 2>&1; then
	echo 'duplicate draft rows accepted' >&2
	exit 1
fi
sed -i.bak '$d' "$index"
rm "$index.bak"

# Both procedures reject mismatched matching-chain metadata.
sed -i.bak 's/"saved-plan-2099_01_01_0000-lifecycle-fixture"/"saved-plan-mismatch"/' "$chain"
if record_draft >/dev/null 2>&1; then
	echo 'mismatched chain accepted while recording' >&2
	exit 1
fi
sed -i.bak 's/"saved-plan-mismatch"/"saved-plan-2099_01_01_0000-lifecycle-fixture"/' "$chain"
rm "$chain.bak"

# Approval is explicit, registration promotes the existing row, and neither operation executes.
if save_approved >/dev/null 2>&1; then
	echo 'unapproved fixture registered' >&2
	exit 1
fi
sed -i.bak 's/status: draft/status: approved/' "$plan"
rm "$plan.bak"
sed -i.bak 's/"saved-plan-2099_01_01_0000-lifecycle-fixture"/"saved-plan-mismatch"/' "$chain"
if save_approved >/dev/null 2>&1; then
	echo 'mismatched chain accepted while registering' >&2
	exit 1
fi
sed -i.bak 's/"saved-plan-mismatch"/"saved-plan-2099_01_01_0000-lifecycle-fixture"/' "$chain"
rm "$chain.bak"
save_approved
[ ! -e "$execution" ]

# Execution has a separate, explicit start boundary.
start_chain
[ -e "$execution" ]

printf '%s\n' 'Lifecycle fixture passed: links and JSON validate; draft recording is idempotent; unregistered, unapproved, duplicate-row, and mismatched-chain cases are rejected; only an explicit start executes.'
