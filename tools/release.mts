/**
 * Programmatic Nx Release script for CI/CD.
 *
 * Runs versioning (conventional commits -> semver) and changelog generation,
 * then outputs which projects changed and their versions as GitHub Actions
 * outputs for selective Docker builds.
 *
 * Dockerfile paths and image names are read from each project's `metadata`
 * field in project.json (no hardcoded map).
 *
 * Usage:
 *   pnpm release                  # real run
 *   pnpm release --dry-run        # preview only
 *   pnpm release --verbose        # verbose logging
 *   pnpm release --first-release  # first release (no prior tags)
 */

import { execSync } from 'node:child_process';
import { appendFileSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { createProjectGraphAsync, workspaceRoot } from '@nx/devkit';
import { releaseChangelog, releaseVersion } from 'nx/release';

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const verbose = args.includes('--verbose');
const noVerify = args.includes('--no-verify');
assertCleanWorktree();
const firstRelease = args.includes('--first-release') || !hasAnyReleaseTag();

if (firstRelease && !args.includes('--first-release')) {
  console.log(
    'No prior release tags found — running in first-release mode automatically.',
  );
}

const graph = await createProjectGraphAsync();

const projectsToRelease = firstRelease
  ? undefined
  : getProjectsWithFileChanges(graph);

const { projectsVersionData, releaseGraph } = await releaseVersion({
  dryRun,
  verbose,
  firstRelease,
  ...(projectsToRelease && { projects: projectsToRelease }),
  ...(noVerify && { gitCommitArgs: '--no-verify' }),
});

const changed = Object.entries(projectsVersionData)
  .filter(
    ([, data]) => data.newVersion && data.newVersion !== data.currentVersion,
  )
  .map(([name, data]) => {
    const meta = graph.nodes[name]?.data.metadata as
      | {
          dockerfile?: string;
          dockerImageName?: string;
          dockerContext?: string;
        }
      | undefined;
    const next = data.newVersion;
    if (!next) {
      return null;
    }
    return {
      projectName: name,
      name: meta?.dockerImageName ?? name,
      version: next,
      dockerfile: meta?.dockerfile,
      // Build context the Dockerfile expects: per-project metadata may override
      // the default repo-root context (e.g. projects that build from their own dir).
      context: meta?.dockerContext ?? '.',
    };
  })
  .filter((p): p is NonNullable<typeof p> => p !== null)
  .filter((p) => p.dockerfile);

if (changed.length === 0) {
  console.log('No projects to release.');
  writeGitHubOutput('released', 'false');
  writeGitHubOutput('matrix', '{"include":[]}');
  process.exit(0);
}

await releaseChangelog({
  releaseGraph,
  versionData: projectsVersionData,
  dryRun,
  verbose,
  firstRelease,
  ...(noVerify && { gitCommitArgs: '--no-verify' }),
});

const matrix = { include: changed };

const versions = Object.fromEntries(changed.map((p) => [p.name, p.version]));

writeGitHubOutput('released', 'true');
writeGitHubOutput('matrix', JSON.stringify(matrix));
writeGitHubOutput('versions', JSON.stringify(versions));

console.log('\nReleased projects:');
for (const p of changed) {
  console.log(`  ${p.name}@${p.version}`);
}
console.log(`\nBuild matrix: ${JSON.stringify(matrix, null, 2)}`);

function assertCleanWorktree(): void {
  let status: string;
  try {
    status = execSync('git status --porcelain=v1 --untracked-files=all', {
      encoding: 'utf-8',
      stdio: ['pipe', 'pipe', 'pipe'],
    }).trim();
  } catch (error) {
    throw new Error('Cannot inspect the release worktree', { cause: error });
  }

  if (status) {
    throw new Error(
      'Release requires a clean worktree. Commit or stash changes before running the release pipeline.',
    );
  }
}

function hasAnyReleaseTag(): boolean {
  try {
    const tag = execSync('git describe --tags --match "*@*" --abbrev=0 HEAD', {
      encoding: 'utf-8',
      stdio: ['pipe', 'pipe', 'pipe'],
    }).trim();
    return tag.length > 0;
  } catch {
    return false;
  }
}

function writeGitHubOutput(key: string, value: string): void {
  const outputFile = process.env.GITHUB_OUTPUT;
  if (outputFile) {
    appendFileSync(outputFile, `${key}=${value}\n`);
  }
}

/**
 * Return only project names whose source root has file changes since their
 * last release tag. Prevents root-level or unrelated commits (e.g. CI config,
 * docs) from triggering spurious version bumps in independent release mode.
 *
 * Falls open: if a project has no prior tag or the git check fails, include it.
 */
function getNxReleaseAllowlist(): Set<string> | null {
  const nxJsonPath = join(workspaceRoot, 'nx.json');
  let nxJson: { release?: { projects?: string[] } };
  try {
    nxJson = JSON.parse(readFileSync(nxJsonPath, 'utf-8')) as typeof nxJson;
  } catch (error) {
    throw new Error(`Cannot read release configuration from ${nxJsonPath}`, {
      cause: error,
    });
  }
  const configured = nxJson.release?.projects;
  if (!configured?.length || configured.includes('*')) {
    return null;
  }
  return new Set(configured);
}

function getProjectsWithFileChanges(
  projectGraph: Awaited<ReturnType<typeof createProjectGraphAsync>>,
): string[] {
  const allowlist = getNxReleaseAllowlist();
  if (allowlist) {
    const ignored = Object.keys(projectGraph.nodes).filter(
      (n) =>
        projectGraph.nodes[n]?.data.root?.startsWith('projects/') &&
        !allowlist.has(n),
    );
    if (ignored.length > 0) {
      console.log(
        `\nNot in nx.json release.projects (skipped): ${ignored.join(', ')}\n`,
      );
    }
  }
  const releaseProjects = Object.keys(projectGraph.nodes).filter((name) => {
    if (!projectGraph.nodes[name]?.data.root?.startsWith('projects/')) {
      return false;
    }
    if (allowlist && !allowlist.has(name)) {
      return false;
    }
    return true;
  });

  const included: { name: string; reason: string }[] = [];
  const skipped: { name: string; reason: string }[] = [];

  for (const name of releaseProjects) {
    const root = projectGraph.nodes[name]?.data.root;
    if (!root) {
      included.push({ name, reason: 'no project root configured' });
      continue;
    }

    let latestTag: string;
    try {
      latestTag = execSync(
        `git describe --tags --match "${name}@*" --abbrev=0 HEAD`,
        { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] },
      ).trim();
    } catch {
      included.push({ name, reason: 'no prior release tag (first release)' });
      continue;
    }

    try {
      const diff = execSync(
        `git diff --name-only ${latestTag}..HEAD -- ${root}/`,
        { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] },
      ).trim();

      if (diff.length > 0) {
        const changedFiles = diff.split('\n');
        included.push({
          name,
          reason: `${changedFiles.length} file(s) changed since ${latestTag}`,
        });
      } else {
        skipped.push({
          name,
          reason: `no file changes since ${latestTag}`,
        });
      }
    } catch {
      included.push({
        name,
        reason: 'git diff failed (included to avoid blocking)',
      });
    }
  }

  console.log('\nRelease filter results:');
  for (const { name, reason } of skipped) {
    console.log(`  ⏭  Skipping ${name} — ${reason}`);
  }
  for (const { name, reason } of included) {
    console.log(`  ✓  Including ${name} — ${reason}`);
  }

  const result = included.map((p) => p.name);

  if (result.length > 0) {
    console.log(`\nFiltering to projects: ${result.join(',')}\n`);
  } else {
    console.log('\nNo projects matched the release filter.\n');
  }

  return result;
}
