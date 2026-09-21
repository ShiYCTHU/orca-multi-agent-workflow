[CmdletBinding()]
param(
    [ValidateSet('claude','dsh')]
    [string]$Executor,

    [ValidateSet('claude','dsh')]
    [string]$Reviewer
)

$ErrorActionPreference = 'Stop'

if (($Executor -and -not $Reviewer) -or ($Reviewer -and -not $Executor)) {
    throw 'Specify both -Executor and -Reviewer, or neither.'
}

if ($Executor -and $Executor -eq $Reviewer) {
    throw 'Executor and Reviewer must use different providers.'
}

$projectRoot = $null
$currentPath = (Get-Location).Path
$probe = Get-Item -LiteralPath $currentPath

while ($null -ne $probe) {
    $gitMarker = Join-Path $probe.FullName '.git'

    if (Test-Path -LiteralPath $gitMarker) {
        $projectRoot = $probe.FullName
        break
    }

    $probe = $probe.Parent
}

if (-not $projectRoot) {
    $projectRoot = $currentPath
}

$projectRoot = (Resolve-Path $projectRoot).Path
$docs = Join-Path $projectRoot 'docs'
$workflow = Join-Path $docs 'multi_agent_workflow.md'
$claudeFile = Join-Path $projectRoot 'CLAUDE.md'

$binDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$roleTool = Join-Path $binDir 'orca-role-config.py'

if (-not (Test-Path $roleTool)) {
    throw "Missing role configuration tool: $roleTool"
}

New-Item -ItemType Directory -Force -Path $docs | Out-Null

if ($Executor) {
    & python $roleTool set `
        --project $projectRoot `
        --executor $Executor `
        --reviewer $Reviewer

    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to write Orca role configuration.'
    }
} else {
    $rolePath = Join-Path $projectRoot '.orca\role_config.json'

    if (Test-Path $rolePath) {
        & python $roleTool validate --project $projectRoot
        if ($LASTEXITCODE -ne 0) {
            throw 'Existing Orca role configuration is invalid.'
        }
    } else {
        & python $roleTool set `
            --project $projectRoot `
            --executor claude `
            --reviewer dsh

        if ($LASTEXITCODE -ne 0) {
            throw 'Failed to create default Orca role configuration.'
        }
    }
}

if (Test-Path $workflow) {
    Write-Host "SKIP: $workflow already exists"
} else {
@'
# Project Multi-Agent Workflow

## Architecture

The deterministic `orca-supervisor` v1.1 owns long waits.
KIMI is the short-lived Runtime Coordinator.

Provider routing is project-configurable and frozen per Run.

Routing A:
- Executor: Claude / configured backend
- Reviewer: DSH / DeepSeek

Routing B:
- Executor: DSH / DeepSeek
- Reviewer: Claude / configured backend

Project default:
`.orca/role_config.json`

Frozen Run routing:
`.orca/roles/<run_id>.json`

Existing Run snapshots are authoritative and must not drift when the
project default changes.

Legacy Runs without a snapshot must not infer historical roles from
the current project default.

GPT-5.6 Terra is used only for genuine strategic arbitration.

Project instructions define WHAT must be achieved.
The global `orca-multi-agent` skill defines HOW it is coordinated.
'@ | Set-Content -Encoding utf8 $workflow

    Write-Host "CREATE: $workflow"
}

if (Test-Path $claudeFile) {
    Write-Host "SKIP: $claudeFile already exists"
} else {
@'
# Claude Agent Instructions

Your active Orca role is determined by the formal Task/Dispatch and the
Run's frozen provider routing.

When acting as Executor:
- implement only the assigned scope;
- preserve unrelated work;
- validate the change;
- report through the assigned Orca lifecycle.

When acting as independent Reviewer through `orca-claude-reviewer`:
- remain review-only;
- do not modify project files;
- return exactly one supported final verdict.

Do not redefine project goals or silently switch provider roles.
'@ | Set-Content -Encoding utf8 $claudeFile

    Write-Host "CREATE: $claudeFile"
}


# Install/update the canonical KIMI Runtime Coordinator policy in CLAUDE.md.
# This is idempotent and applies even when CLAUDE.md already existed.

$coordinatorStart = '<!-- ORCA_KIMI_COORDINATOR_V1_START -->'
$coordinatorEnd = '<!-- ORCA_KIMI_COORDINATOR_V1_END -->'

$coordinatorLines = @(
    '<!-- ORCA_KIMI_COORDINATOR_V1_START -->',
    '',
    '## KIMI Runtime Coordinator — mandatory Orca policy',
    '',
    'When `ORCA_SUPERVISOR_MODE=1` is set, you are the SHORT-LIVED KIMI Runtime Coordinator, not an Executor or Reviewer.',
    '',
    'Before performing any orchestration, read the authoritative global workflow files:',
    '',
    '- `$HOME/.codex/skills/orca-multi-agent/SKILL.md`',
    '- `$HOME/.codex/skills/orca-multi-agent/references/current_system.md`',
    '- `$HOME/.codex/skills/orca-multi-agent/references/workflow.md`',
    '- the project-local `docs/multi_agent_workflow.md`',
    '',
    'The Run frozen role snapshot is authoritative.',
    '',
    '### Routing B: DSH Executor -> Claude Reviewer',
    '',
    '- DSH Executor MUST run through `orca-dsh-executor`.',
    '- NEVER launch raw `dsh` or raw `dsh-orca` as the Executor.',
    '- NEVER use `worker-start --agent dsh`.',
    '- Create a formal Orca Task and Dispatch to the dedicated Executor terminal.',
    '- Supply the exact Dispatch preamble and bounded Task to `orca-dsh-executor`.',
    '- The OUTER adapter owns heartbeat and `worker_done` settlement.',
    '- The inner DSH process MUST NOT invoke Orca lifecycle commands.',
    '- Independent Claude review MUST run through `orca-claude-reviewer`.',
    '',
    '### Routing A: Claude Executor -> DSH Reviewer',
    '',
    '- Claude Executor uses the formal Orca native Claude worker route.',
    '- DSH Reviewer remains independent and must use the formal DSH review lifecycle.',
    '- Never silently switch providers because of auth, quota, launcher, or procedural failure.',
    '',
    'KIMI must never remain alive waiting for workers, reviewers, monitors, or long simulations.',
    'When healthy long-running work is active, return `SUPERVISOR_RETURN_ACTIVE`.',
    '',
    '<!-- ORCA_KIMI_COORDINATOR_V1_END -->'
)

$coordinatorBlock = $coordinatorLines -join "`n"

$existingClaude = if (Test-Path $claudeFile) {
    [System.IO.File]::ReadAllText($claudeFile)
} else {
    ''
}

if (
    $existingClaude.Contains($coordinatorStart) -and
    $existingClaude.Contains($coordinatorEnd)
) {
    $a = $existingClaude.IndexOf($coordinatorStart)
    $b = $existingClaude.IndexOf($coordinatorEnd, $a)
    $b = $b + $coordinatorEnd.Length

    $existingClaude =
        $existingClaude.Substring(0, $a) +
        $coordinatorBlock +
        $existingClaude.Substring($b)
}
else {
    if ($existingClaude.Length -gt 0 -and -not $existingClaude.EndsWith("`n")) {
        $existingClaude += "`n"
    }

    $existingClaude += "`n" + $coordinatorBlock + "`n"
}

$claudeUtf8 = New-Object System.Text.UTF8Encoding($false)

[System.IO.File]::WriteAllText(
    $claudeFile,
    $existingClaude.Replace("`r`n", "`n").Replace("`r", "`n"),
    $claudeUtf8
)

Write-Host 'KIMI coordinator policy ready in CLAUDE.md.'

Write-Host 'Project layer ready.'

& python $roleTool show --project $projectRoot

Write-Host 'Next: orca-kimi'
