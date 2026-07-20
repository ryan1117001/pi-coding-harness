/**
 * Combines per-project Cobertura XML coverage reports into a single
 * self-contained HTML dashboard at coverage/index.html.
 *
 * Expects Cobertura XML at coverage/projects/<name>/{coverage,cobertura-coverage}.xml
 * — produced by pytest-cov (Python projects) and vitest --coverage (web).
 *
 * Usage: tsx tools/coverage-report.ts
 */

import {
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  writeFileSync,
} from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const COVERAGE_DIR = path.join(ROOT, 'coverage', 'projects');

interface ProjectCoverage {
  name: string;
  linesValid: number;
  linesCovered: number;
  lineRate: number;
  branchesValid: number;
  branchesCovered: number;
  branchRate: number;
  /** Relative path from coverage/ to the detail index.html, or null. */
  htmlReportHref: string | null;
}

function parseFloat0(val: string | undefined): number {
  return val ? parseFloat(val) : 0;
}

function parseInt0(val: string | undefined): number {
  return val ? parseInt(val, 10) : 0;
}

function parseCobertura(
  xmlPath: string,
): Omit<ProjectCoverage, 'name' | 'htmlReportHref'> | null {
  if (!existsSync(xmlPath)) return null;

  const xml = readFileSync(xmlPath, 'utf-8');
  const coverageTag = xml.match(/<coverage\s[^>]*>/);
  if (!coverageTag) return null;

  const attr = (name: string) =>
    coverageTag[0].match(new RegExp(`${name}="([^"]*)"`))?.[1];

  return {
    linesValid: parseInt0(attr('lines-valid')),
    linesCovered: parseInt0(attr('lines-covered')),
    lineRate: parseFloat0(attr('line-rate')),
    branchesValid: parseInt0(attr('branches-valid')),
    branchesCovered: parseInt0(attr('branches-covered')),
    branchRate: parseFloat0(attr('branch-rate')),
  };
}

function discoverProjects(): ProjectCoverage[] {
  if (!existsSync(COVERAGE_DIR)) {
    console.error(`Coverage directory not found: ${COVERAGE_DIR}`);
    console.error(
      'Run tests with coverage first:\n  pnpm exec nx run-many -t test\n  pnpm exec nx test web --coverage',
    );
    process.exit(1);
  }

  const entries = readdirSync(COVERAGE_DIR, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .sort((a, b) => a.name.localeCompare(b.name));

  const projects: ProjectCoverage[] = [];

  const XML_NAMES = ['coverage.xml', 'cobertura-coverage.xml'];

  for (const entry of entries) {
    const xmlPath = XML_NAMES.map((f) =>
      path.join(COVERAGE_DIR, entry.name, f),
    ).find(existsSync);
    const parsed = xmlPath ? parseCobertura(xmlPath) : null;
    if (!parsed) {
      console.warn(`  skipping ${entry.name} — no coverage.xml found`);
      continue;
    }

    const htmlCandidates = [
      {
        abs: path.join(COVERAGE_DIR, entry.name, 'html', 'index.html'),
        href: `projects/${entry.name}/html/index.html`,
      },
      {
        abs: path.join(COVERAGE_DIR, entry.name, 'index.html'),
        href: `projects/${entry.name}/index.html`,
      },
    ];
    const htmlHit = htmlCandidates.find((c) => existsSync(c.abs));
    projects.push({
      name: entry.name,
      ...parsed,
      htmlReportHref: htmlHit?.href ?? null,
    });
  }

  return projects;
}

function pct(n: number): string {
  return `${(n * 100).toFixed(1)}%`;
}

function ratingClass(rate: number): string {
  if (rate >= 0.8) return 'high';
  if (rate >= 0.5) return 'medium';
  return 'low';
}

function generateHtml(projects: ProjectCoverage[]): string {
  const totalLines = projects.reduce((s, p) => s + p.linesValid, 0);
  const totalCoveredLines = projects.reduce((s, p) => s + p.linesCovered, 0);
  const totalBranches = projects.reduce((s, p) => s + p.branchesValid, 0);
  const totalCoveredBranches = projects.reduce(
    (s, p) => s + p.branchesCovered,
    0,
  );

  const overallLineRate = totalLines > 0 ? totalCoveredLines / totalLines : 0;
  const overallBranchRate =
    totalBranches > 0 ? totalCoveredBranches / totalBranches : 0;

  const timestamp = new Date().toLocaleString('en-US', {
    dateStyle: 'medium',
    timeStyle: 'short',
  });

  const rows = projects
    .map((p) => {
      const detailLink = p.htmlReportHref
        ? `<a href="${p.htmlReportHref}">${p.name}</a>`
        : p.name;

      return `
        <tr>
          <td class="project-name">${detailLink}</td>
          <td class="${ratingClass(p.lineRate)}">${pct(p.lineRate)}</td>
          <td>${p.linesCovered.toLocaleString()} / ${p.linesValid.toLocaleString()}</td>
          <td class="${ratingClass(p.branchRate)}">${pct(p.branchRate)}</td>
          <td>${p.branchesCovered.toLocaleString()} / ${p.branchesValid.toLocaleString()}</td>
        </tr>`;
    })
    .join('\n');

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Coverage — workspace</title>
<style>
  :root {
    --bg: #0f1117;
    --surface: #1a1d27;
    --border: #2a2d3a;
    --text: #e1e4ed;
    --text-muted: #8b8fa3;
    --high: #34d399;
    --medium: #fbbf24;
    --low: #f87171;
    --accent: #818cf8;
  }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: "SF Mono", "Cascadia Code", "Fira Code", ui-monospace, monospace;
    background: var(--bg);
    color: var(--text);
    padding: 2rem;
    line-height: 1.5;
  }
  h1 { font-size: 1.25rem; font-weight: 600; margin-bottom: 0.25rem; }
  .subtitle { color: var(--text-muted); font-size: 0.8rem; margin-bottom: 2rem; }

  .summary {
    display: flex;
    gap: 1.5rem;
    margin-bottom: 2rem;
  }
  .metric-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 1.25rem 1.5rem;
    min-width: 180px;
  }
  .metric-label { font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.08em; color: var(--text-muted); margin-bottom: 0.25rem; }
  .metric-value { font-size: 1.75rem; font-weight: 700; }
  .metric-detail { font-size: 0.75rem; color: var(--text-muted); margin-top: 0.25rem; }

  table { width: 100%; border-collapse: collapse; background: var(--surface); border: 1px solid var(--border); border-radius: 8px; overflow: hidden; }
  thead { background: var(--border); }
  th { text-align: left; padding: 0.6rem 1rem; font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.08em; color: var(--text-muted); font-weight: 500; }
  td { padding: 0.6rem 1rem; font-size: 0.8rem; border-top: 1px solid var(--border); }
  tr:hover td { background: rgba(255,255,255,0.02); }
  .project-name a { color: var(--accent); text-decoration: none; }
  .project-name a:hover { text-decoration: underline; }
  .high { color: var(--high); font-weight: 600; }
  .medium { color: var(--medium); font-weight: 600; }
  .low { color: var(--low); font-weight: 600; }

  tfoot td { font-weight: 700; border-top: 2px solid var(--border); }
</style>
</head>
<body>
  <h1>Coverage Report</h1>
  <p class="subtitle">workspace monorepo &mdash; generated ${timestamp}</p>

  <div class="summary">
    <div class="metric-card">
      <div class="metric-label">Line coverage</div>
      <div class="metric-value ${ratingClass(overallLineRate)}">${pct(overallLineRate)}</div>
      <div class="metric-detail">${totalCoveredLines.toLocaleString()} / ${totalLines.toLocaleString()} lines</div>
    </div>
    <div class="metric-card">
      <div class="metric-label">Branch coverage</div>
      <div class="metric-value ${ratingClass(overallBranchRate)}">${pct(overallBranchRate)}</div>
      <div class="metric-detail">${totalCoveredBranches.toLocaleString()} / ${totalBranches.toLocaleString()} branches</div>
    </div>
    <div class="metric-card">
      <div class="metric-label">Projects</div>
      <div class="metric-value">${projects.length}</div>
      <div class="metric-detail">with coverage data</div>
    </div>
  </div>

  <table>
    <thead>
      <tr>
        <th>Project</th>
        <th>Line %</th>
        <th>Lines</th>
        <th>Branch %</th>
        <th>Branches</th>
      </tr>
    </thead>
    <tbody>
      ${rows}
    </tbody>
    <tfoot>
      <tr>
        <td>Total</td>
        <td class="${ratingClass(overallLineRate)}">${pct(overallLineRate)}</td>
        <td>${totalCoveredLines.toLocaleString()} / ${totalLines.toLocaleString()}</td>
        <td class="${ratingClass(overallBranchRate)}">${pct(overallBranchRate)}</td>
        <td>${totalCoveredBranches.toLocaleString()} / ${totalBranches.toLocaleString()}</td>
      </tr>
    </tfoot>
  </table>
</body>
</html>`;
}

// ── main ──

const projects = discoverProjects();

if (projects.length === 0) {
  console.error('No coverage data found. Run tests with coverage first.');
  process.exit(1);
}

console.log(`Found coverage for ${projects.length} projects:`);
for (const p of projects) {
  console.log(
    `  ${p.name.padEnd(16)} lines ${pct(p.lineRate).padStart(6)}  branches ${pct(p.branchRate).padStart(6)}`,
  );
}

const outDir = path.join(ROOT, 'coverage');
if (!existsSync(outDir)) mkdirSync(outDir, { recursive: true });

const outPath = path.join(outDir, 'index.html');
writeFileSync(outPath, generateHtml(projects), 'utf-8');
console.log(`\nCombined report written to ${path.relative(ROOT, outPath)}`);
