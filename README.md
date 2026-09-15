# Orca Multi-Agent Workflow

Portable Ubuntu package for the current supervised Orca architecture:

```text
Supervisor v1.1
  -> KIMI short-lived Coordinator
      -> Claude Executor (backend configured as GLM in Claude Code)
      -> DSH / DeepSeek independent Reviewer
      -> GPT-5.6 Terra strategic Arbitrator (explicit escalation only)
```

GPT-5.6 Luna / `orca-luna` is legacy and is not installed by this repository.

## What is included

- `bin/orca-supervisor`: deterministic long-wait and event supervisor.
- `bin/orca-kimi`: short-lived KIMI coordinator launcher.
- `bin/orca-terra`: GPT-5.6 Terra arbitrator launcher.
- `bin/orca-init`: adds the current project-local workflow documents without overwriting existing files.
- `bin/dsh-orca`: DSH / DeepSeek reviewer launcher.
- `skill/orca-multi-agent`: Codex skill and the current workflow references.

No API keys, tokens, provider credentials, machine-specific project paths, or DSH environment files are included.

## Dependencies

Install and authenticate these separately:

- Ubuntu with Bash and Python 3.
- Orca, with `orca-ide` available in `PATH`.
- Claude Code, with `claude` available in `PATH`. Configure its executor backend (currently GLM) in Claude Code itself.
- Codex CLI, with `codex` available in `PATH` and access to `gpt-5.6-terra`.
- DSH, with `dsh` available in `PATH`.
- A DSH environment file at `~/.config/dsh/orca.env`. Keep credentials only in this local file; do not commit it.

The launchers intentionally preserve the current local policy flags (`--dangerously-skip-permissions` for KIMI and `danger-full-access` for Terra). Use only on projects where that access is acceptable.

## Install on another Ubuntu machine

```bash
git clone YOUR_GITHUB_REPOSITORY_URL
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

1. Configure Claude Code so its own default backend is GLM; do not pass a provider model through Orca.
2. Create `~/.config/dsh/orca.env` with the environment required by your DSH installation, and protect it with `chmod 600`.
3. Authenticate Orca, Claude Code, Codex, and DSH using their own supported setup flows.
4. In a project that does not already have local workflow instructions, run `orca-init` once.
5. Start one bounded coordinator turn:

   ```bash
   cd /path/to/project
   ORCA_SUPERVISOR_MODE=1 orca-kimi
   ```

6. After KIMI returns the real Run ID, start the long-lived supervisor:

   ```bash
   orca-supervisor --run REAL_RUN_ID --project /path/to/project --no-initial-kick
   ```

## Smoke tests

From the cloned repository:

```bash
./smoke-test.sh
./install.sh --check
orca-supervisor --self-test
```

- `smoke-test.sh` checks packaged syntax, executable bits, portability, and common secret patterns.
- `install.sh --check` checks required commands and DSH configuration without changing files.
- `orca-supervisor --self-test` verifies the installed runtime commands and reports the active model roles.

For a non-destructive installation rehearsal:

```bash
temporary_home="$(mktemp -d)"
HOME="$temporary_home" ./install.sh
HOME="$temporary_home" ./install.sh --uninstall
```

## Uninstall

```bash
./install.sh --uninstall
```

Uninstall moves only files that match this repository's current copies into a timestamped backup. If an installed file was edited after installation, the script leaves it in place and reports it.

## Roll back an upgrade

Each forced install and uninstall prints its backup directory. Restore it with:

```bash
cp -a BACKUP_DIRECTORY/. "$HOME/"
```

Rollback is explicit; the installer never deletes or overwrites existing local configuration without `--force`.
