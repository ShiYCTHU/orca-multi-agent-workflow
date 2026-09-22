---
name: orca-multi-agent
description: Coordinate supervised, cost-aware multi-agent work through Orca when the user requests an Orca workflow, multiple executing or reviewing agents, cross-model verification, or high-capability GPT oversight with cheaper workers. Do not use for an unsupervised full handoff to one agent.
---

# Orca Multi-Agent — ACTIVE GLOBAL POLICY

## 1. Current architecture

This is the ONLY active default Orca architecture.

- Deterministic lifecycle supervisor:
  `orca-supervisor` v1.1

- Routine Runtime Coordinator:
  KIMI through `orca-kimi`

- Strategic Arbitrator:
  GPT-5.6 Terra, only after explicit escalation

Executor and independent Reviewer are role-configurable.

Supported provider routings:

Routing A:

`Executor = claude`
`Reviewer = dsh`

- Claude Executor uses the Orca-native worker route.
- Claude Code owns its configured backend, currently GLM.
- DSH / DeepSeek performs independent review.

Routing B:

`Executor = dsh`
`Reviewer = claude`

- DSH / DeepSeek performs implementation through the Orca DSH Executor adapter.
- Claude Code using its configured backend performs independent review.

Executor and Reviewer MUST use different providers.

The project default provider pair is stored in:

`<project>/.orca/role_config.json`

For every supervised Run, `orca-supervisor` freezes the resolved provider
pair into:

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

That Run snapshot is authoritative for the lifetime of the Run.

Changing the project default later MUST NOT alter an already-frozen Run.
A newly created Run may freeze the new project default.

The historical `orca-luna` / GPT-5.6 Luna coordinator architecture is
LEGACY and MUST NOT be selected as the default workflow.

Do not reconstruct the current architecture from old conversations.

## 2. Mandatory global reading

For every request involving:

- Orca multi-agent work;
- Run / Task / Dispatch lifecycle;
- Supervisor operation;
- Coordinator operation;
- recovery;
- Executor / Reviewer routing;
- agent orchestration;

read these files first:

1. `references/current_system.md`
2. `references/workflow.md`
3. applicable project `AGENTS.md`
4. authoritative project task plan
5. project-local `docs/multi_agent_workflow.md` if present

`references/current_system.md` is the current global source of truth for
Orca mechanics and model roles.

Project task plans remain authoritative for scientific scope, numerical
requirements, acceptance criteria, allowed files, and user authorizations.

## 3. User-facing bootstrap rule

If the user asks to START actual Orca work, do not merely describe an
agent DAG.

Do not make the user manually act as Runtime Coordinator.

Do not say vague things such as:

- "start your usual Orca/Codex session"
- "open the orchestrator"
- "launch your normal coordinator"
- "start Luna"

For a fresh task, explicitly provide:

### 可执行 Bash 命令

The command must explicitly launch:

`ORCA_SUPERVISOR_MODE=1 orca-kimi`

from the real project directory.

Run `orca-init` first only if initialization is actually needed.

Then provide exactly one consolidated block labelled:

### 发给 KIMI 的文本（不是 Bash）

The KIMI bootstrap instruction must state that KIMI is a SHORT-LIVED
Runtime Coordinator and must:

1. read global/project rules;
2. preserve the dirty worktree;
3. create exactly one fresh Orca Run for a fresh task;
4. persist the authoritative task plan into durable project/Orca state;
5. create/dispatch only currently authorized work;
6. resolve the Run's frozen Executor/Reviewer provider pair before dispatch;
7. obey the active Routing A or Routing B provider contract;
8. use Terra only for genuine strategic arbitration;
9. never remain alive waiting for workers, reviewers, monitors, or CFD jobs;
10. report the actual Run ID, Task ID(s), Dispatch ID(s), and terminal(s);
11. return immediately after healthy long-running work becomes active.

Normal final state:

`SUPERVISOR_RETURN_ACTIVE`

After the REAL Run ID is known, provide exactly one Supervisor command:

`orca-supervisor --run REAL_RUN_ID --project /real/project/path`

Fresh startup waits without waking KIMI. Use `--recovery-kick` only for an
interrupted existing Run that needs an immediate `SAME_RUN_RECOVERY` turn.

Never put a fake or placeholder Run ID in an executable command.

## 4. Coordinator lifetime

KIMI is NOT the long-running Supervisor.

Correct architecture:

deterministic Python Supervisor
-> wakes short-lived KIMI
-> KIMI performs one bounded coordination turn
-> KIMI dispatches or adjudicates work
-> KIMI returns
-> Python Supervisor waits again

A KIMI turn ending is NORMAL.

It does not mean:

- Run failure;
- Task failure;
- worker failure;
- Reviewer failure;
- CFD failure;
- Dispatch failure.

Long waits belong to `orca-supervisor`.

## 5. Fresh-task lifecycle

For a fresh task:

1. launch KIMI;
2. KIMI creates one fresh Run;
3. KIMI establishes repository baseline;
4. KIMI persists the authoritative task plan;
5. KIMI dispatches only the currently authorized first work unit(s);
6. KIMI returns real lifecycle IDs;
7. KIMI exits;
8. user launches `orca-supervisor` using the actual Run ID.

Do not create all future gated Tasks speculatively.

Later short-lived KIMI turns advance the DAG after evidence is available.

## 6. SAME_RUN_RECOVERY

Interrupted existing work defaults to:

`SAME_RUN_RECOVERY`

Do not create a new Run merely because a Coordinator conversation ended.

Inspect durable:

- Run state;
- Task DAG;
- Dispatches;
- Deliveries/messages;
- terminals;
- Executor/Reviewer state;
- reports;
- logs;
- evidence directories;
- owned CFD/monitor processes.

Identify the first genuinely unfinished gate.

If healthy work already exists, preserve it and return.

## 7. FINALIZATION_INTERRUPTED

If substantive work already completed but lifecycle closure was interrupted,
classify:

`FINALIZATION_INTERRUPTED`

Examples include:

- Reviewer produced a substantive result but worker_done failed;
- computation completed but Delivery was not acknowledged;
- Task completed but final Coordinator adjudication was interrupted;
- report exists but lifecycle metadata is incomplete.

Verify substantive evidence and repair only the missing lifecycle/reporting
state.

Do not rerun completed computation or review merely to generate a fresh
completion message.

## 8. Executor rule

The Executor route is determined by the Run's frozen role snapshot.

Routing A — Claude Executor:

`worker-start --agent claude`

Do not pass GLM/KIMI/provider model overrides through Orca.
Claude Code's own configuration owns its backend.

Routing B — DSH Executor:

DSH is not a native Orca worker.

Never use:

`worker-start --agent dsh`

A DSH Executor requires:

- a custom Orca shell terminal;
- a formal Orca Task;
- a formal Dispatch to that terminal;
- the exact Dispatch preamble;
- the installed adapter `orca-dsh-executor`.

The Dispatch preamble is authoritative for Task ID, Dispatch ID,
assignee terminal, heartbeat, question, escalation, and worker_done
provenance.

Coordinator and Executor must remain separate sessions/processes.

## 9. Reviewer rule

The independent Reviewer route is determined by the Run's frozen role
snapshot.

Routing A — DSH Reviewer:

DSH is not a native Orca worker.

Never use:

`worker-start --agent dsh`

Never use raw:

`dsh ...`

The canonical DSH runtime is:

`dsh-orca --profile headless "<review task>"`

It must still operate under a formal Orca Task/Dispatch lifecycle.

Routing B — Claude Reviewer:

Use an independent review Task and Dispatch together with:

`orca-claude-reviewer`

Claude Reviewer is review-only. It must not modify, create, delete,
rename, format, or repair project source files.

The adapter parses exactly one final verdict:

`FINAL_VERDICT: PASS`

or

`FINAL_VERDICT: CHANGES_REQUIRED`

or

`FINAL_VERDICT: ESCALATION_REQUIRED`

and performs formal Orca worker_done settlement.

Implementation agents must not self-certify independent review.

Provider failure, authentication failure, quota failure, or launcher
failure MUST NOT silently switch the Run to the opposite provider pair.

## 10. Terra escalation

GPT-5.6 Terra is the strategic arbitrator.

Use it only after:

`SUPERVISOR_ESCALATE_TERRA`

Appropriate reasons include:

- materially contradictory durable Orca state;
- conflicting Executor/Reviewer technical evidence;
- repeated bounded revisions fail to converge;
- major numerical/physical architecture decision;
- Coordinator cannot safely identify the next authoritative gate.

Do NOT invoke Terra merely for:

- normal PASS/REVISE;
- ordinary worker_done;
- active workers;
- routine recovery;
- resource pressure;
- first JIT compilation;
- known CLI procedural errors;
- missing user authorization.

## 11. Cross-project resource isolation

Multiple Orca projects may run concurrently.

Classify resources:

- CURRENT_RUN_OWNED
- OTHER_RUN_OR_PROJECT
- UNKNOWN_OWNERSHIP

Only CURRENT_RUN_OWNED resources may be controlled.

OTHER_RUN_OR_PROJECT and UNKNOWN_OWNERSHIP are read-only.

Never broadly kill/signal/suspend/renice/reset:

- Python
- JAX
- XLA
- LLVM
- Claude
- Codex
- DSH
- notebooks
- CFD
- compiler/test
- GPU

processes simply because they are visible or expensive.

GPU visibility is not proof of ownership.

## 12. Resource failure classification

Do not automatically classify the following as numerical/code failure:

- LLVM allocation failure;
- XLA compile-memory exhaustion;
- CUDA OOM caused by contention;
- first-JIT latency;
- CPU oversubscription;
- one isolated timeout;
- transient resource contention.

First classify as:

`RESOURCE_PRESSURE`

If unresolved after bounded current-Run-only mitigation:

`RESOURCE_LIMIT`

Do not weaken scientific/numerical acceptance criteria to make a
resource-limited test pass.

## 13. Repository safety

Before modifications record:

- branch;
- HEAD;
- `git status --short`;
- relevant existing diff.

Never automatically use:

- `git reset`
- `git clean`
- `git checkout --`
- `git restore .`

Do not overwrite unrelated dirty work.

Do not commit or push without explicit authorization.

## 14. Multi-agent DAG design

Parallelism is allowed when ownership is independent.

For bugs spanning shared semantics, prefer:

parallel read-only evidence gathering
-> one implementation decision gate
-> one source-writing Executor
-> bounded validation
-> independent Reviewer

Do not let multiple agents independently edit overlapping shared semantics.

The user should not manually issue every phase prompt when KIMI can own the
phase/gate lifecycle.

## 15. Long-running CFD and expensive jobs

Long jobs require the authorization defined by the project task plan or
explicit user approval.

Before launch establish:

- authoritative initial state;
- CPU/GPU allocation;
- wall-clock budget;
- disk budget;
- output location;
- checkpoint/restart strategy;
- soft-stop condition;
- hard-stop condition;
- monitoring strategy;
- ownership.

Do not start duplicate production jobs.

If a healthy authorized job already exists:

- preserve it;
- do not launch another;
- Coordinator returns;
- Supervisor waits.

## 16. Historical rules

Historical Orca policy is archived under:

`references/legacy/`

Those files are historical evidence only.

They are NOT active policy.

<!-- ORCA_DASHBOARD_SKILL_V1_START -->

## Progress Dashboard integration

The current Orca workflow includes the read-only
Orca Progress Dashboard v1.

Before coordinating a fresh Run or recovering an existing Run,
read and follow:

- `references/current_system.md`
- `references/workflow.md`

The Dashboard rules in `references/current_system.md` are part of
the current active Orca workflow.

### Fresh Run

After creating the real fresh Run ID, KIMI should create one
high-level progress manifest using `orca-progress`.

The progress manifest is only a human-facing visualization plan.
It does NOT pre-create future gated Orca Tasks.

Prefer approximately 5-10 high-level trunk phases.

### Runtime updates

Before every Supervisor-facing KIMI return, update the progress
manifest when one exists.

Keep the visual state synchronized with durable Orca evidence.

Bind real Task / Dispatch / Terminal identifiers when applicable.

Completed phases should contain a concise evidence-grounded summary.

Future phases should contain a concise purpose.

Allowed visual states are:

- planned
- ready
- active
- completed
- revision
- blocked
- escalated
- skipped

Never invent numeric percentage completion.

### Separation of responsibilities

The Dashboard is strictly read-only observability.

The lifecycle architecture remains:

Deterministic Python Supervisor
-> KIMI Runtime Coordinator
-> Claude Executor
-> DSH / DeepSeek Reviewer
-> GPT-5.6 Terra only for genuine strategic escalation

Dashboard failure must never be treated as Run failure.

`orca-luna` remains legacy and is not restored by the Dashboard.

<!-- ORCA_DASHBOARD_SKILL_V1_END -->

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
