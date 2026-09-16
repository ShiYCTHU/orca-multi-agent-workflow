[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$Check,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
$binDir = Join-Path $HOME '.local\bin'
$skillDir = Join-Path $HOME '.codex\skills\orca-multi-agent'
$stateDir = Join-Path $HOME '.local\state\orca-multi-agent-installer'
$pathMarker = Join-Path $stateDir 'windows-path-added'
$files = @(
    @{ Source = 'bin/orca-supervisor'; Target = (Join-Path $binDir 'orca-supervisor.py') }
    @{ Source = 'windows/orca-supervisor.cmd'; Target = (Join-Path $binDir 'orca-supervisor.cmd') }
    @{ Source = 'windows/orca-kimi.cmd'; Target = (Join-Path $binDir 'orca-kimi.cmd') }
    @{ Source = 'windows/orca-terra.cmd'; Target = (Join-Path $binDir 'orca-terra.cmd') }
    @{ Source = 'windows/orca-init.cmd'; Target = (Join-Path $binDir 'orca-init.cmd') }
    @{ Source = 'windows/orca-init.ps1'; Target = (Join-Path $binDir 'orca-init.ps1') }
    @{ Source = 'windows/dsh-orca.cmd'; Target = (Join-Path $binDir 'dsh-orca.cmd') }
    @{ Source = 'skill/orca-multi-agent/SKILL.md'; Target = (Join-Path $skillDir 'SKILL.md') }
    @{ Source = 'skill/orca-multi-agent/references/workflow.md'; Target = (Join-Path $skillDir 'references\workflow.md') }
    @{ Source = 'skill/orca-multi-agent/references/current_system.md'; Target = (Join-Path $skillDir 'references\current_system.md') }
)

function Test-SameFile($source, $target) {
    (Get-FileHash $source).Hash -eq (Get-FileHash $target).Hash
}

function Get-BackupPath($backup, $target) {
    $relative = $target.Substring($HOME.Length).TrimStart([char[]]'\/')
    Join-Path $backup $relative
}

function Add-BinToPath {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @($userPath -split ';' | Where-Object { $_ })
    if ($entries -notcontains $binDir) {
        [Environment]::SetEnvironmentVariable(
            'Path',
            (($entries + $binDir) -join ';'),
            'User'
        )
        New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
        Set-Content -Encoding ascii -Path $pathMarker -Value $binDir
        Write-Host "Added to user PATH: $binDir"
    }
}

function Remove-BinFromPath {
    if (-not (Test-Path $pathMarker)) { return }
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @($userPath -split ';' | Where-Object { $_ -and $_ -ne $binDir })
    [Environment]::SetEnvironmentVariable('Path', ($entries -join ';'), 'User')
    Remove-Item $pathMarker
}

if ($Check) {
    $missing = $false
    foreach ($command in 'python', 'orca-ide', 'claude', 'codex', 'dsh') {
        if (Get-Command $command -ErrorAction SilentlyContinue) {
            Write-Host "OK      $command"
        } else {
            Write-Host "MISSING $command"
            $missing = $true
        }
    }
    if ($missing) { exit 1 }
    exit 0
}

if ($Uninstall) {
    $backup = Join-Path $stateDir ('backups\uninstall-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $moved = $false
    foreach ($file in $files) {
        $source = Join-Path $PSScriptRoot $file.Source
        if (-not (Test-Path $file.Target)) { continue }
        if (Test-SameFile $source $file.Target) {
            $destination = Get-BackupPath $backup $file.Target
            New-Item -ItemType Directory -Force -Path (Split-Path $destination) | Out-Null
            Move-Item $file.Target $destination
            $moved = $true
        } else {
            Write-Host "KEEP modified file: $($file.Target)"
        }
    }
    if ($moved) {
        Remove-BinFromPath
        Write-Host "Uninstalled matching files. Backup: $backup"
    } else {
        Write-Host 'No matching installed files found.'
    }
    exit 0
}

$conflicts = @($files | Where-Object { Test-Path $_.Target })
if ($conflicts.Count -and -not $Force) {
    [Console]::Error.WriteLine("Existing targets found; no files changed:`n  " + (($conflicts.Target) -join "`n  "))
    exit 2
}

if ($conflicts.Count) {
    $backup = Join-Path $stateDir ('backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    foreach ($file in $conflicts) {
        $destination = Get-BackupPath $backup $file.Target
        New-Item -ItemType Directory -Force -Path (Split-Path $destination) | Out-Null
        Copy-Item $file.Target $destination
    }
    Write-Host "Backup: $backup"
}

foreach ($file in $files) {
    $source = Join-Path $PSScriptRoot $file.Source
    New-Item -ItemType Directory -Force -Path (Split-Path $file.Target) | Out-Null
    Copy-Item -Force $source $file.Target
}

Add-BinToPath
Write-Host 'Installed. Open a new terminal and restart Codex Desktop.'
