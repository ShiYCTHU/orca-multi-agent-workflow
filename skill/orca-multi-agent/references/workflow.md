# Orca Multi-Agent Workflow — ACTIVE

Version: Supervisor v1.1
Default Runtime Coordinator: KIMI

This file contains the CURRENT workflow only.

Historical Luna-based coordination rules are archived and are not active.

## Current roles

User / Strategic Master
    |
    v
Deterministic Python Supervisor (`orca-supervisor` v1.1)
    |
    v
KIMI short-lived Runtime Coordinator (`orca-kimi`)
    |
    +--> role-configured Executor
    |
    +--> independent role-configured Reviewer
    |
    +--> GPT-5.6 Terra strategic arbitration only when explicitly escalated

Supported provider pairs:

Routing A:

`Claude Executor -> DSH / DeepSeek Reviewer`

Routing B:

`DSH / DeepSeek Executor -> Claude Reviewer`

The project default is:

`<project>/.orca/role_config.json`

When the Supervisor first resolves a Run, the selected pair is frozen at:

`<project>/.orca/roles/<run_id>.json`

Supervisor startup routing visibility:

Whenever `orca-supervisor` starts for a real Run, it resolves the Run role
snapshot before the first coordination turn and prints the effective frozen
routing in the startup log, for example:

`Frozen routing: dsh -> claude`

It also prints the authoritative role snapshot source.

If a safe frozen routing cannot be resolved, including an unfrozen legacy
Run whose historical provider pair cannot be inferred safely, startup must
show:

`Frozen routing: UNRESOLVED / BLOCKED`

The Supervisor must never display a guessed provider pair as authoritative.

Legacy Run migration rule:

Runs created before Run-level role freezing was deployed may not have a
`.orca/roles/<run_id>.json` snapshot. If such a Run is resumed without a
snapshot, the Supervisor MUST NOT infer its historical provider pair from
the project's current default. It must block until the provider pair is
backfilled from durable evidence. Existing snapshots always remain
authoritative.

The frozen Run snapshot is authoritative for all later coordination turns
for that Run.

Changing the project default affects future Runs only. It must not change
an existing frozen Run.

`orca-luna` is LEGACY and must not be used as the default Coordinator.

## Fresh-task bootstrap

The assistant should minimize manual user operations.

Canonical Coordinator launch:

    cd /real/project/path
    ORCA_SUPERVISOR_MODE=1 orca-kimi

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
      --project /real/project/path \
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

## Provider routing

### Routing A

Executor:

`worker-start --agent claude`

Do not specify the backend model through Orca.

Independent Reviewer:

DSH / DeepSeek under a formal Orca Task/Dispatch lifecycle.

Use the canonical DSH runtime:

`dsh-orca --profile headless "<review task>"`

Never raw `dsh`.

Never `worker-start --agent dsh`.

### Routing B

Executor:

DSH / DeepSeek under a custom Orca shell terminal plus formal Task and
Dispatch.

Use:

`orca-dsh-executor`

with the exact Orca Dispatch preamble and bounded Executor task.

Never `worker-start --agent dsh`.

Independent Reviewer:

Claude Code under an independent review Task/Dispatch.

Use:

`orca-claude-reviewer`

The Claude Reviewer is review-only and must not modify project source files.

### Run role freeze

Before dispatching new Executor or Reviewer work, the Supervisor resolves
the Run's frozen provider snapshot.

Project default:

`<project>/.orca/role_config.json`

Frozen Run configuration:

`<project>/.orca/roles/<run_id>.json`

Once frozen, the provider pair must remain unchanged for the lifetime of
that Run.

Do not silently fall back to the opposite provider pair because of
authentication, quota, launcher, model, or procedural failure.

Preserve the same Run and completed evidence, then diagnose or report the
blocker.

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

<!-- ORCA_DASHBOARD_WORKFLOW_V1_START -->

## Progress Dashboard lifecycle

The active Orca workflow includes a read-only progress visualization layer.

The lifecycle is:

User
-> KIMI creates fresh Run
-> KIMI creates high-level progress manifest
-> KIMI dispatches currently authorized Orca work
-> KIMI returns SUPERVISOR_RETURN_ACTIVE
-> deterministic Python Supervisor waits
-> worker_done / question / escalation occurs
-> Supervisor wakes a new bounded KIMI coordination turn
-> KIMI inspects durable Orca state
-> KIMI adjudicates the current gate
-> KIMI updates the progress manifest
-> KIMI dispatches next authorized work when appropriate
-> KIMI returns a Supervisor-facing state

The progress manifest lives at:

<project>/.orca/progress/<run_id>.json

The browser Dashboard reads this manifest through orca-dashboard.

The Dashboard never owns lifecycle state.

### Fresh Run

After KIMI creates the real Run ID:

1. define approximately 5-10 human-readable high-level phases;
2. create the progress manifest using orca-progress init;
3. mark already completed initialization work as completed;
4. mark currently authorized work as active or ready;
5. keep future high-level phases as planned;
6. bind real Task, Dispatch, and Terminal identifiers when they exist.

Creating a planned visual phase does not create an Orca Task.

### Coordination turns

During every later KIMI coordination turn:

1. inspect durable Orca state first;
2. identify the real current gate;
3. update completed visual nodes with short evidence-grounded summaries;
4. update active, revision, blocked, or escalated state as appropriate;
5. bind newly created Task, Dispatch, and Terminal identifiers;
6. update the manifest before returning control to the Supervisor.

Do not infer completion from process disappearance alone.

### Review and bounded repair

Typical visual lifecycle:

Implementation
-> Validation
-> Independent Review

If Reviewer returns PASS:

Independent Review
-> Delivery

If Reviewer returns CHANGES_REQUIRED:

Independent Review
-> Revision
-> Validation
-> Independent Review

A repair loop does not require a new Run.

The same high-level node may temporarily enter revision.

If useful for human clarity, a bounded repair may also appear as a child node.

### SAME_RUN_RECOVERY

For interrupted existing work:

- do not create a new Run merely to recreate a Dashboard;
- inspect the existing durable Run;
- reuse the existing progress manifest when present;
- if the Run predates Dashboard support and no manifest exists, KIMI may reconstruct one from durable evidence;
- reconstructed status must reflect verified durable state;
- never mark historical phases completed without evidence.

### FINALIZATION_INTERRUPTED

If substantive work is already complete but lifecycle closure was interrupted:

- preserve completed evidence;
- mark the corresponding visual phase according to verified evidence;
- repair only the missing lifecycle closure;
- do not rerun completed CFD, validation, or review merely to make the Dashboard look complete.

### Dashboard failure

Dashboard failure is observability failure only.

It must not:

- stop workers;
- stop Reviewers;
- stop CFD;
- change Run state;
- create a new Run;
- trigger Terra;
- convert a healthy Run into BLOCKED.

The Dashboard can be restarted independently with:

orca-dashboard --run REAL_RUN_ID --project /absolute/project/path

### Status vocabulary

Only use:

- planned
- ready
- active
- completed
- revision
- blocked
- escalated
- skipped

Do not show invented numeric percentages for active agents or simulations.

<!-- ORCA_DASHBOARD_WORKFLOW_V1_END -->

## 2026-09-19 Orca compatibility requirements

The current Orca/Supervisor integration has three global compatibility
requirements.

1. Successful Run-role resolution may omit the `error` key. Use tolerant
   access such as:

   `role_error = role.get("error") or "(none)"`

2. `orca orchestration check --wait --json` may return a timeout envelope
   with `result.count == 0` and an empty `messages` list. This is NOT an
   Orca event and MUST NOT wake KIMI with `reason=ORCA_EVENT`.

3. The terminal consuming the Run mailbox must be bound to the target Run.
   Before starting the long-lived Supervisor, check the current binding with
   `orca orchestration run-current --json`. Use
   `orca orchestration run-use --id <run_id> --json` only when binding or
   rebinding is actually required.

Do not bind a Supervisor/coordinator mailbox to an Executor terminal merely
because that terminal is live.
