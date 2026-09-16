# Orca Multi-Agent Workflow — ACTIVE

Version: Supervisor v1.1
Default Runtime Coordinator: KIMI

This file contains the CURRENT workflow only.

Historical Luna-based coordination rules are not active and are not packaged.

## Current roles

User / Strategic Master
    |
    v
Deterministic Python Supervisor (`orca-supervisor` v1.1)
    |
    v
KIMI short-lived Runtime Coordinator (`orca-kimi`)
    |
    +--> Claude Executor (`worker-start --agent claude`)
    |
    +--> DSH / DeepSeek Independent Reviewer
    |    (`dsh-orca --profile headless "<review task>"`)
    |
    +--> GPT-5.6 Terra strategic arbitration only when explicitly escalated

`orca-luna` is LEGACY and must not be used as the default Coordinator.

## Fresh-task bootstrap

The assistant should minimize manual user operations.

Canonical Coordinator launch on Ubuntu/WSL:

    cd /real/project/path
    ORCA_SUPERVISOR_MODE=1 orca-kimi

On Windows PowerShell:

    Set-Location C:\real\project\path
    $env:ORCA_SUPERVISOR_MODE='1'; orca-kimi

The user then sends ONE consolidated task/bootstrap prompt.

Initial KIMI turn:

1. read global/project rules;
2. inspect repository baseline;
3. create exactly one fresh Run;
4. persist the task plan;
5. create/dispatch only currently authorized work;
6. report actual Run/Task/Dispatch/terminal IDs;
7. return immediately after healthy work is active.

Normal final line:

    SUPERVISOR_RETURN_ACTIVE

After a real Run ID exists:

    orca-supervisor \
      --run REAL_RUN_ID \
      --project REAL_PROJECT_PATH \
      --no-initial-kick

The deterministic Supervisor owns all long waits.

## Supervisor cycle

worker/reviewer/CFD active
-> Python Supervisor waits
-> worker_done / question / escalation
-> fresh short-lived KIMI coordination turn
-> PASS / REVISE / dispatch / user gate / escalation
-> KIMI exits
-> Supervisor waits again

KIMI ending a turn is normal.

## Return states

Allowed Supervisor-facing states:

    SUPERVISOR_RETURN_ACTIVE
    SUPERVISOR_RETURN_ADVANCED
    SUPERVISOR_RETURN_USER_ACTION
    SUPERVISOR_RETURN_TERMINAL
    SUPERVISOR_RETURN_BLOCKED
    SUPERVISOR_ESCALATE_TERRA

USER_ACTION / TERMINAL / BLOCKED are pause-or-stop states for Supervisor v1.1.

## SAME_RUN_RECOVERY

Coordinator interruption does not imply work failure.

Default:

    COORDINATOR_TURN_INTERRUPTED
        ->
    SAME_RUN_RECOVERY

Inspect durable state and recover from the first unfinished gate.

Do not duplicate healthy:

- Runs;
- Tasks;
- Dispatches;
- workers;
- Reviewers;
- CFD jobs;
- monitors.

## FINALIZATION_INTERRUPTED

If substantive work completed but lifecycle finalization did not:

    FINALIZATION_INTERRUPTED

Repair only missing:

- Delivery handling;
- Task completion;
- Coordinator adjudication;
- summary/report lifecycle metadata.

Do not redo substantive computation merely to manufacture a new completion
message.

## Executor

Use:

    worker-start --agent claude

Do not specify backend model through Orca.

## Reviewer

Use only:

    dsh-orca --profile headless "<review task>"

Never raw `dsh`.

Never `worker-start --agent dsh`.

## Terra

Use only for genuine strategic ambiguity after:

    SUPERVISOR_ESCALATE_TERRA

Routine coordination belongs to KIMI.

## Multi-agent structure

For shared-semantics bugs prefer:

    parallel read-only evidence gathering
        ->
    implementation decision gate
        ->
    one source-writing Executor
        ->
    validation
        ->
    independent Reviewer

KIMI owns this orchestration.

The user should not manually feed phase prompts one-by-one unless a real
user authorization/scientific decision is required.

## Resource isolation

Classify resources:

    CURRENT_RUN_OWNED
    OTHER_RUN_OR_PROJECT
    UNKNOWN_OWNERSHIP

Only CURRENT_RUN_OWNED resources may be controlled.

Do not broadly kill unrelated or unknown processes.

## Repository safety

Preserve dirty worktrees.

No automatic destructive git cleanup.

No commit/push without authorization.

## Long jobs

Do not duplicate healthy production CFD jobs.

Long waits belong to the deterministic Supervisor, not KIMI.

## Authority

Global workflow defines HOW work is coordinated.

Project task plans define WHAT must scientifically be achieved.
