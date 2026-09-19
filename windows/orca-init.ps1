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

$projectRoot = (& git rev-parse --show-toplevel 2>$null)
if (-not $projectRoot) {
    $projectRoot = (Get-Location).Path
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

Write-Host 'Project layer ready.'

& python $roleTool show --project $projectRoot

Write-Host 'Next: orca-kimi'
