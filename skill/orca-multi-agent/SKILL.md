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

- Implementation Executor:
  Claude through `worker-start --agent claude`

- Executor backend:
  owned by Claude Code configuration; currently GLM

- Independent Reviewer:
  DSH / DeepSeek through `dsh-orca`

- Strategic Arbitrator:
  GPT-5.6 Terra, only after explicit escalation

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
6. use `worker-start --agent claude` for implementation Executor work;
7. use `dsh-orca --profile headless "<review task>"` for independent review;
8. use Terra only for genuine strategic arbitration;
9. never remain alive waiting for workers, reviewers, monitors, or CFD jobs;
10. report the actual Run ID, Task ID(s), Dispatch ID(s), and terminal(s);
11. return immediately after healthy long-running work becomes active.

Normal final state:

`SUPERVISOR_RETURN_ACTIVE`

After the REAL Run ID is known, provide exactly one Supervisor command:

`orca-supervisor --run REAL_RUN_ID --project /real/project/path --no-initial-kick`

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

Canonical Executor route:

`worker-start --agent claude`

Do not pass GLM/KIMI/provider model overrides through Orca.

Claude Code's own configuration owns its backend.

Coordinator and Executor must remain separate sessions/processes.

## 9. Reviewer rule

DSH is not a native Orca worker.

Never use:

`worker-start --agent dsh`

Never fall back to:

`dsh ...`

Canonical Reviewer invocation:

`dsh-orca --profile headless "<review task>"`

Do not invent unsupported DSH lifecycle commands.

Implementation agents must not self-certify independent review.

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

GPT-5.6 Luna / `orca-luna` is historical only and is not packaged as active
policy. It MUST NOT be selected as the default workflow.
