# Orca Multi-Agent System — CURRENT SOURCE OF TRUTH

Status: ACTIVE

Architecture:

    orca-supervisor v1.1
        |
        v
    KIMI short-lived Coordinator
        |
        +--> Claude / configured GLM Executor
        +--> DSH / DeepSeek Reviewer
        +--> GPT-5.6 Terra strategic arbitration

The current default Runtime Coordinator is KIMI.

The historical `orca-luna` / GPT-5.6 Luna Coordinator is LEGACY.

If another global Orca document conflicts with this file regarding:

- Coordinator identity;
- Coordinator lifetime;
- bootstrap command;
- Supervisor ownership;
- Executor routing;
- Reviewer routing;
- Terra escalation;

THIS FILE governs global orchestration mechanics.

Project-specific scientific requirements remain governed by the user's
current task plan and project instructions.

# Canonical launchers

## KIMI Coordinator

Ubuntu/WSL:

    ORCA_SUPERVISOR_MODE=1 orca-kimi

Windows PowerShell:

    $env:ORCA_SUPERVISOR_MODE='1'; orca-kimi

KIMI is short-lived.

It performs ONE bounded coordination turn and returns.

It does not remain online waiting for long-running work.

## Claude Executor

    worker-start --agent claude

Do not override the configured backend model through Orca.

## DSH Reviewer

    dsh-orca --profile headless "<review task>"

Never use raw `dsh`.

## Terra Arbitrator

GPT-5.6 Terra is used only after:

    SUPERVISOR_ESCALATE_TERRA

# Fresh-task user experience

If the user says:

- use my Orca workflow;
- start Orca;
- start this multi-agent task;
- directly begin execution;

the assistant must help START the system.

Do not merely describe the agent DAG.

Do not make the user manually coordinate phases.

The assistant should normally output:

## 可执行命令

Ubuntu/WSL:

    cd /real/project/path
    ORCA_SUPERVISOR_MODE=1 orca-kimi

Windows PowerShell:

    Set-Location C:\real\project\path
    $env:ORCA_SUPERVISOR_MODE='1'; orca-kimi

Run `orca-init` first only if the project is not already initialized.

Then:

## 发给 KIMI 的文本（不是命令）

Provide ONE consolidated KIMI bootstrap task.

The prompt must require KIMI to:

1. identify itself as short-lived Runtime Coordinator;
2. read applicable global/project rules;
3. establish repository baseline;
4. create exactly one fresh Run;
5. persist the authoritative task plan;
6. create and dispatch only currently authorized work;
7. use Claude for implementation;
8. use DSH for independent review;
9. use Terra only for strategic escalation;
10. not wait for workers/Reviewers/CFD;
11. return actual:
    - Run ID
    - Task ID(s)
    - Dispatch ID(s)
    - terminal(s)
12. return immediately.

Normal final line:

    SUPERVISOR_RETURN_ACTIVE

After the REAL Run ID is returned, provide:

    orca-supervisor \
      --run REAL_RUN_ID \
      --project REAL_PROJECT_PATH \
      --no-initial-kick

Never put a fake Run ID into an executable command.

# Interrupted-task user experience

For interrupted work, use the platform-appropriate launch command above, then
provide `SAME_RUN_RECOVERY`. On Ubuntu/WSL that launch is:

    cd /real/project/path
    ORCA_SUPERVISOR_MODE=1 orca-kimi

The consolidated instruction must contain:

    SAME_RUN_RECOVERY

KIMI must inspect durable state.

It must not create a fresh Run unless durable evidence proves that is needed.

# Coordinator lifetime

Correct lifecycle:

    long work active
        ->
    Python Supervisor waits
        ->
    event occurs
        ->
    KIMI wakes
        ->
    KIMI makes bounded decision
        ->
    KIMI exits
        ->
    Python Supervisor waits again

Conversation lifetime is not work lifetime.

# SAME_RUN_RECOVERY

Coordinator turn termination does not imply:

- Run termination;
- worker termination;
- Reviewer termination;
- CFD termination;
- Dispatch failure.

Recover the SAME Run and find the first unfinished gate.

# FINALIZATION_INTERRUPTED

When substantive work completed but lifecycle closure did not:

    FINALIZATION_INTERRUPTED

Verify evidence and repair lifecycle/reporting only.

Do not repeat completed work just to create a fresh worker_done.

# Resource ownership

Classify:

    CURRENT_RUN_OWNED
    OTHER_RUN_OR_PROJECT
    UNKNOWN_OWNERSHIP

Unknown and other-project resources are read-only.

# Model-role separation

    Coordinator  = KIMI
    Executor     = Claude / configured GLM backend
    Reviewer     = DSH / DeepSeek
    Arbitrator   = GPT-5.6 Terra

# Historical policy

GPT-5.6 Luna / `orca-luna` is historical only, is not packaged here, and is
not active policy.
