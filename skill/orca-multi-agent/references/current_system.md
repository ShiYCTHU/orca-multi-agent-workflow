# Orca Multi-Agent System — CURRENT SOURCE OF TRUTH

Status: ACTIVE

Architecture:

    orca-supervisor v1.1
        |
        v
    KIMI short-lived Coordinator
        |
        +--> role-configured Executor
        +--> independent role-configured Reviewer
        +--> GPT-5.6 Terra strategic arbitration

Supported provider pairs:

Routing A:

`Claude / configured GLM Executor -> DSH / DeepSeek Reviewer`

Routing B:

`DSH / DeepSeek Executor -> Claude / configured backend Reviewer`

The project-level default is stored in:

`<project>/.orca/role_config.json`

For each supervised Run, the selected roles are frozen in:

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

The Run snapshot is authoritative after it exists.

Changing the project default later affects only Runs that have not yet
been frozen.

The current default Runtime Coordinator is KIMI.

The historical `orca-luna` / GPT-5.6 Luna Coordinator is LEGACY.

If another global Orca document conflicts with this file regarding:

- Coordinator identity;
- Coordinator lifetime;
- bootstrap command;
- Supervisor ownership;
- Executor routing;
- Reviewer routing;
- Run role freezing;
- Terra escalation;

THIS FILE governs global orchestration mechanics.

Project-specific scientific requirements remain governed by the user's
current task plan and project instructions.

# Canonical launchers

## KIMI Coordinator

    ORCA_SUPERVISOR_MODE=1 orca-kimi

KIMI is short-lived.

It performs ONE bounded coordination turn and returns.

It does not remain online waiting for long-running work.

## Routing A

Claude Executor:

`worker-start --agent claude`

Do not override the configured backend model through Orca.

DSH / DeepSeek Reviewer:

Use a formal Orca review Task/Dispatch and the canonical DSH runtime:

`dsh-orca --profile headless "<review task>"`

Never use raw `dsh`.

Never use `worker-start --agent dsh`.

## Routing B

DSH / DeepSeek Executor:

DSH is non-native and requires a custom Orca terminal, formal Task,
formal Dispatch, exact Dispatch preamble, and:

`orca-dsh-executor`

Never use `worker-start --agent dsh`.

Claude Reviewer:

Use an independent review Task/Dispatch and:

`orca-claude-reviewer`

Claude Reviewer is review-only and must not modify project source files.

## Run role freezing

Project default:

`<project>/.orca/role_config.json`

Frozen Run snapshot:

`<project>/.orca/roles/<run_id>.json`

The first valid Supervisor resolution freezes the Run's provider pair.

After freezing, later edits to the project default MUST NOT alter that
Run.

A new Run may freeze a different supported provider pair.

Invalid project configuration or invalid Run snapshot is a blocker.
Never silently substitute another provider pair.

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

## 可执行 Bash 命令

    cd /real/project/path
    ORCA_SUPERVISOR_MODE=1 orca-kimi

Run `orca-init` first only if the project is not already initialized.

Then:

## 发给 KIMI 的文本（不是 Bash）

Provide ONE consolidated KIMI bootstrap task.

The prompt must require KIMI to:

1. identify itself as short-lived Runtime Coordinator;
2. read applicable global/project rules;
3. establish repository baseline;
4. create exactly one fresh Run;
5. persist the authoritative task plan;
6. create and dispatch only currently authorized work;
7. resolve and obey the Run's frozen Executor/Reviewer provider pair;
8. follow Routing A or Routing B without silent provider fallback;
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
      --project /real/project/path

Fresh startup does not wake KIMI. For interrupted existing work that needs an
immediate durable-state coordination turn, add `--recovery-kick`.

Never put a fake Run ID into an executable command.

# Interrupted-task user experience

For interrupted work:

    cd /real/project/path
    ORCA_SUPERVISOR_MODE=1 orca-kimi

Then provide ONE consolidated instruction containing:

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

Coordinator:

`KIMI`

Routing A:

`Executor = Claude / configured GLM backend`

`Reviewer = DSH / DeepSeek`

Routing B:

`Executor = DSH / DeepSeek`

`Reviewer = Claude / configured backend`

Arbitrator:

`GPT-5.6 Terra`

Executor and Reviewer must always use different providers.

Role selection is project-configurable but Run-frozen.

No provider may silently assume the other provider's role because of
launcher failure, authentication failure, quota, or procedural error.

# Historical policy

Archived material under:

    references/legacy/

is historical evidence only.

It is not active policy.

<!-- ORCA_PROGRESS_DASHBOARD_V1_START -->

## Orca Progress Dashboard v1

The Orca workflow includes a read-only progress visualization layer.

Architecture:

KIMI Runtime Coordinator
-> <project>/.orca/progress/<run_id>.json
-> orca-dashboard
-> local browser on 127.0.0.1

The Dashboard is observability only.

It MUST NOT control or modify:

- Orca Run lifecycle
- Task lifecycle
- Dispatch lifecycle
- Executor processes
- Reviewer processes
- CFD processes
- Supervisor decisions

Dashboard failure is NOT Orca Run failure.

### Fresh Run progress plan

When KIMI creates exactly one fresh Orca Run, it should also create
one high-level progress manifest for that Run.

The progress manifest is a VISUAL PLAN only.

Creating planned visualization nodes does NOT mean creating future
gated Orca Tasks.

Prefer approximately 5-10 human-readable trunk nodes, for example:

- Intake / Rules
- Investigation
- Design Gate
- Implementation
- Validation
- Independent Review
- Delivery

Parallel read-only investigations may appear as optional child nodes.

Do not represent every shell command or tiny internal action.

### Create manifest

After the real Run ID exists, KIMI should create the manifest with:

orca-progress init \
  --run REAL_RUN_ID \
  --project /absolute/project/path \
  --title "Short human-readable task title" \
  --plan-file -

The node plan is provided as JSON on stdin.

### Update manifest

Whenever KIMI creates, dispatches, adjudicates, revises, blocks,
or completes real Orca work, it should update the corresponding
high-level visual node.

Example:

orca-progress patch \
  --run REAL_RUN_ID \
  --project /absolute/project/path \
  --node implementation \
  --status active \
  --task task_xxx \
  --dispatch ctx_xxx

When a node completes, KIMI should also provide a concise,
evidence-grounded 1-3 sentence summary.

Before every Supervisor-facing KIMI return, update the progress
manifest when the Run has one.

### Allowed visualization states

Use only:

- planned
- ready
- active
- completed
- revision
- blocked
- escalated
- skipped

Do not invent numerical percentage-complete values for active
Claude workers, Reviewers, validation jobs, or CFD.

### Run / Task / Dispatch mapping

Whenever possible, bind real lifecycle identifiers to the visual node:

- task_ids
- dispatch_ids
- terminal_ids

One visual node may correspond to multiple real Tasks or Dispatches.

The visual node is NOT itself an Orca Task.

### Human-readable text

For unfinished nodes, purpose explains the task goal.

For completed nodes, summary explains what was actually accomplished.

Never mark a node completed merely because a process disappeared.

Use durable Orca evidence and normal lifecycle adjudication.

### Dashboard launch

The read-only Dashboard command is:

orca-dashboard \
  --run REAL_RUN_ID \
  --project /absolute/project/path

The browser automatically refreshes the progress manifest.

The Dashboard may be stopped and restarted at any time without
changing the Orca Run.

<!-- ORCA_PROGRESS_DASHBOARD_V1_END -->

<!-- ORCA_SUPERVISE_UI_V1_START -->

## Preferred Supervisor + Dashboard launch

After KIMI has created the real authoritative Run ID and returned control
to the user, the preferred launch command is:

orca-supervise-ui --run REAL_RUN_ID --project /absolute/project/path

This command starts:

1. the read-only Orca Progress Dashboard;
2. the deterministic orca-supervisor, whose fresh-start default does not kick KIMI.

The Dashboard remains optional observability only.

If the Dashboard fails to start, that failure must not be treated as an
Orca Run failure.

The underlying authoritative lifecycle remains:

deterministic Python Supervisor
-> short-lived KIMI Runtime Coordinator
-> Claude Executor
-> DSH / DeepSeek Reviewer
-> GPT-5.6 Terra only for genuine strategic escalation

The user may still launch the components separately when needed:

orca-dashboard --run REAL_RUN_ID --project /absolute/project/path

orca-supervisor --run REAL_RUN_ID --project /absolute/project/path

Do not use placeholder Run IDs in executable commands.

<!-- ORCA_SUPERVISE_UI_V1_END -->

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
