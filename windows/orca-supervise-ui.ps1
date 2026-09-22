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
$binDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$supervisor = Join-Path $binDir 'orca-supervisor.py'

Write-Host 'Checking coordinator Run binding...'

& python $supervisor --run $Run --project $Project --check-binding
if ($LASTEXITCODE -ne 0) {
    throw "Failed to verify coordinator Run binding for $Run"
}

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

& python $supervisor `
    --run $Run `
    --project $Project

$supervisorExit = $LASTEXITCODE
Write-Host "Orca Supervisor exited with code: $supervisorExit"
Write-Host 'Dashboard was intentionally left running.'
exit $supervisorExit
