[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Run,

    [Parameter(Mandatory = $true)]
    [string]$Project,

    [int]$Port = 8765
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -PathType Container $Project)) {
    throw "Project directory does not exist: $Project"
}

$Project = (Resolve-Path $Project).Path

Write-Host 'Checking coordinator Run binding...'

$currentJson = (& orca orchestration run-current --json 2>$null | Out-String)
$currentRun = $null

if ($currentJson) {
    try {
        $current = $currentJson | ConvertFrom-Json

        if ($current.result.run -is [string]) {
            $currentRun = $current.result.run
        } elseif ($null -ne $current.result.run) {
            $currentRun = $current.result.run.id
        }
    } catch {
        $currentRun = $null
    }
}

if ($currentRun -ne $Run) {
    if ($currentRun) {
        Write-Host "Current terminal is bound to: $currentRun"
    } else {
        Write-Host 'Current terminal is not bound to an Orca Run.'
    }

    Write-Host "Binding coordinator terminal to: $Run"

    & orca orchestration run-use --id $Run --json

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to bind coordinator terminal to Run $Run"
    }
} else {
    Write-Host "Coordinator terminal already bound to: $Run"
}

$binDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$stateDir = Join-Path $HOME '.local\state\orca-dashboard'
$safeRun = $Run -replace '[^A-Za-z0-9_.-]', '_'
$dashboardLog = Join-Path $stateDir "$safeRun.log"
$dashboardErrorLog = Join-Path $stateDir "$safeRun.error.log"

New-Item -ItemType Directory -Force -Path $stateDir | Out-Null

$dashboard = Join-Path $binDir 'orca-dashboard.py'
$dashboardArguments = @(
    ('"' + $dashboard + '"'),
    '--run', ('"' + $Run + '"'),
    '--project', ('"' + $Project + '"'),
    '--port', $Port
)

$dashboardProcess = Start-Process -FilePath 'python' `
    -ArgumentList $dashboardArguments `
    -RedirectStandardOutput $dashboardLog `
    -RedirectStandardError $dashboardErrorLog `
    -PassThru

Write-Host "Dashboard PID: $($dashboardProcess.Id)"
Write-Host "Dashboard log: $dashboardLog"
Write-Host 'Dashboard is independent of Supervisor lifecycle.'

& python (Join-Path $binDir 'orca-supervisor.py') `
    --run $Run `
    --project $Project `
    --no-initial-kick

$supervisorExit = $LASTEXITCODE
Write-Host "Orca Supervisor exited with code: $supervisorExit"
Write-Host 'Dashboard was intentionally left running.'
exit $supervisorExit
