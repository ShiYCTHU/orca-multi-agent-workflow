$ErrorActionPreference = 'Stop'

$projectRoot = (& git rev-parse --show-toplevel 2>$null)
if (-not $projectRoot) { $projectRoot = (Get-Location).Path }

$docs = Join-Path $projectRoot 'docs'
$workflow = Join-Path $docs 'multi_agent_workflow.md'
$claudeFile = Join-Path $projectRoot 'CLAUDE.md'
New-Item -ItemType Directory -Force -Path $docs | Out-Null

if (Test-Path $workflow) {
    Write-Host "SKIP: $workflow already exists"
} else {
    @'
# Project Multi-Agent Workflow

## Architecture

- Supervisor: deterministic `orca-supervisor` v1.1; owns long waits.
- Runtime Coordinator: short-lived KIMI via `orca-kimi`.
- Executor: Claude via `worker-start --agent claude`; Claude Code owns its configured GLM backend.
- Independent Reviewer: DSH / DeepSeek via `dsh-orca --profile headless "<review task>"`.
- Strategic Arbitrator: GPT-5.6 Terra, only after `SUPERVISOR_ESCALATE_TERRA`.
- Legacy: GPT-5.6 Luna / `orca-luna`; never select it as the default Coordinator.

Project instructions define what must be achieved. The global `orca-multi-agent` skill defines how it is coordinated.
'@ | Set-Content -Encoding utf8 $workflow
    Write-Host "CREATE: $workflow"
}

if (Test-Path $claudeFile) {
    Write-Host "SKIP: $claudeFile already exists"
} else {
    @'
# Claude Executor Instructions

You are the bounded implementation Executor, not the Runtime Coordinator or independent Reviewer.

Read `docs/multi_agent_workflow.md`, preserve the dirty worktree, follow the assigned Orca Task/Dispatch scope and acceptance criteria, use Claude Code's configured backend, validate your work, and return one valid `worker_done` through the assigned Dispatch context.

Do not redefine goals, expand scope, modify unauthorized files, self-approve independent review, or pass a provider model override through Orca.
'@ | Set-Content -Encoding utf8 $claudeFile
    Write-Host "CREATE: $claudeFile"
}

Write-Host 'Project layer ready.'
Write-Host 'Next: orca-kimi'
