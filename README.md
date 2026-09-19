# Orca Multi-Agent Workflow

Portable Windows and Ubuntu package for the current supervised Orca architecture:

```text
Supervisor v1.1
  -> KIMI short-lived Coordinator
      -> role-configured Executor
      -> independent role-configured Reviewer
      -> GPT-5.6 Terra strategic Arbitrator
```

Supported provider pairs:

- Routing A: Claude / configured backend Executor -> DSH / DeepSeek Reviewer
- Routing B: DSH / DeepSeek Executor -> Claude / configured backend Reviewer

Project default routing lives in `.orca/role_config.json`.
Each supervised Run freezes its effective pair in
`.orca/roles/<run_id>.json`.

GPT-5.6 Luna / `orca-luna` is legacy and is not installed by this repository.

## What is included

- `bin/orca-supervisor`: deterministic long-wait and event supervisor.
- `bin/orca-progress`: atomic progress-manifest creator and updater.
- `bin/orca-dashboard`: read-only local Dashboard server.
- `bin/orca-supervise-ui`: starts the Dashboard independently, then runs the Supervisor.
- `bin/orca-kimi`: short-lived KIMI coordinator launcher.
- `bin/orca-terra`: GPT-5.6 Terra arbitrator launcher.
- `bin/orca-init`: adds the current project-local workflow documents without overwriting existing files.

- `bin/orca-role-config`: manages project defaults and inspects frozen Run routing.
- `bin/orca-dsh-executor`: Routing B DSH Executor adapter.
- `bin/orca-claude-reviewer`: Routing B independent Claude Reviewer adapter.
- `bin/dsh-orca`: DSH / DeepSeek reviewer launcher.
- `skill/orca-multi-agent`: Codex skill and the current workflow references.
- `install.ps1` and `windows/`: native Windows installer and launchers.

No API keys, tokens, provider credentials, machine-specific project paths, or DSH environment files are included.

## Dependencies

Install and authenticate these separately:

- Windows 10/11 with PowerShell and Python 3, or Ubuntu with Bash and Python 3.
- Orca, with `orca` available in native Windows or `orca-ide` available in Ubuntu/WSL. Set `ORCA_CLI_COMMAND` only when your installation uses a different executable path.
- Claude Code, with `claude` available in `PATH`. Configure its executor backend (currently GLM) in Claude Code itself.
- Codex CLI, with `codex` available in `PATH` and access to `gpt-5.6-terra`.
- DSH, with `dsh` available in `PATH`.
- On Ubuntu, a DSH environment file at `~/.config/dsh/orca.env`. On Windows, configure DSH credentials through its normal user environment/configuration. Never commit credentials here.

The launchers intentionally preserve the current local policy flags (`--dangerously-skip-permissions` for KIMI and `danger-full-access` for Terra). Use only on projects where that access is acceptable.

## Install on Windows

Use native PowerShell if Orca, Claude, Codex, and DSH are installed in Windows:

```powershell
git clone https://github.com/ShiYCTHU/orca-multi-agent-workflow.git
cd orca-multi-agent-workflow
powershell.exe -ExecutionPolicy Bypass -File .\install.ps1
```

The installer copies launchers to `%USERPROFILE%\.local\bin`, installs the skill under `%USERPROFILE%\.codex\skills\orca-multi-agent`, and appends the launcher directory to the user `PATH`. Open a new terminal and restart Codex Desktop afterward.

It stops before changing files if a target already exists. To back up and replace an older installation:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\install.ps1 -Force
```

Windows smoke tests:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\install.ps1 -Check
orca-supervisor --self-test
```

If your tools run inside WSL rather than native Windows, use the Ubuntu instructions below inside WSL. Do not mix native Windows launchers with WSL executables.

## Install on Ubuntu or WSL

```bash
git clone https://github.com/ShiYCTHU/orca-multi-agent-workflow.git
cd orca-multi-agent-workflow
./install.sh
```

The installer copies launchers to `~/.local/bin` and the skill to `~/.codex/skills/orca-multi-agent`. It stops before making changes if any target already exists.

If the other machine already has an older copy, review it first, then run:

```bash
./install.sh --force
```

`--force` saves replaced files under `~/.local/state/orca-multi-agent-installer/backups/TIMESTAMP/` before installing. It never changes provider credentials or other Orca/Claude/Codex/DSH configuration.

Ensure `~/.local/bin` is in `PATH`, then restart Codex Desktop so it discovers the skill.

## Configure and use


### Choose provider routing

Routing A is the default:

    orca-init

Explicit Routing A:

    orca-init --executor claude --reviewer dsh

Explicit Routing B:

    orca-init --executor dsh --reviewer claude

On native Windows PowerShell:

    orca-init -Executor claude -Reviewer dsh
    orca-init -Executor dsh -Reviewer claude

Changing the project default affects only future, not-yet-frozen Runs.
Existing `.orca/roles/<run_id>.json` snapshots remain authoritative.

Inspect project default:

    orca-role-config show --project "$PWD"

Inspect a frozen Run:

    orca-role-config show-run --project "$PWD" --run REAL_RUN_ID

Supervisor startup prints the effective frozen provider pair.

Legacy Runs without a trustworthy snapshot block rather than guessing
historical roles.

Before starting the long-lived Supervisor, the coordinator terminal must
be bound to the target Run. `orca-supervise-ui` performs the required
`run-current` / conditional `run-use` check.

1. Configure Claude Code so its own default backend is GLM; do not pass a provider model through Orca.
2. On Ubuntu/WSL, create `~/.config/dsh/orca.env` with the environment required by DSH and protect it with `chmod 600`. On native Windows, use DSH's normal user environment/configuration.
3. Authenticate Orca, Claude Code, Codex, and DSH using their own supported setup flows.
4. In a project that does not already have local workflow instructions, run `orca-init` once.
5. Start one bounded coordinator turn. On Ubuntu/WSL:

   ```bash
   cd /path/to/project
   ORCA_SUPERVISOR_MODE=1 orca-kimi
   ```

   On native Windows:

   ```powershell
   Set-Location C:\path\to\project
   orca-kimi
   ```

6. After KIMI returns the real Run ID, start the Supervisor and read-only Dashboard. On Ubuntu/WSL:

   ```bash
   orca-supervise-ui --run REAL_RUN_ID --project /path/to/project
   ```

   On native Windows PowerShell:

   ```powershell
   orca-supervise-ui -Run REAL_RUN_ID -Project C:\path\to\project
   ```

   The Dashboard remains available if the Supervisor exits. It is observability
   only and never controls the Run. To run without it, use
   `orca-supervisor --run REAL_RUN_ID --project /path/to/project --no-initial-kick`.

## Smoke tests

From the cloned repository:

```bash
./smoke-test.sh
./install.sh --check
orca-supervisor --self-test
```

- `smoke-test.sh` checks packaged syntax, progress-manifest behavior, Dashboard validation, executable bits, portability, and common secret patterns.
- `install.sh --check` checks required commands and DSH configuration without changing files.
- `orca-supervisor --self-test` verifies the installed runtime commands and reports the active model roles.

For a non-destructive installation rehearsal:

```bash
temporary_home="$(mktemp -d)"
HOME="$temporary_home" ./install.sh
HOME="$temporary_home" ./install.sh --uninstall
```

## Uninstall

Ubuntu/WSL:

```bash
./install.sh --uninstall
```

Windows:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
```

Uninstall moves only files that match this repository's current copies into a timestamped backup. If an installed file was edited after installation, the script leaves it in place and reports it.

## Roll back an upgrade

Each forced install and uninstall prints its backup directory. Restore it with:

```bash
cp -a BACKUP_DIRECTORY/. "$HOME/"
```

On Windows, copy the contents of the printed backup directory back into `%USERPROFILE%`, preserving its directory structure.

Rollback is explicit; the installer never deletes or overwrites existing local configuration without `--force`.
