---
plan: quick-9
subsystem: documentation/skill
tags: [skill, mesh, actors, services, job, collections, list]
key-files:
  modified:
    - tools/skill/mesh/skills/actors/SKILL.md
    - tools/skill/mesh/skills/collections/SKILL.md
    - tools/skill/mesh/SKILL.md
decisions:
  - "Service section placed before See Also in actors/SKILL.md to keep See Also as final section per existing convention"
  - "Limiter example simplified in docs (Check only) vs full test file — keeps documentation focused"
  - "bare map/filter/reduce note added as inline comment in existing example rather than separate rule to avoid duplication with Global Collection Functions section"
  - "list_concat.mpl example adapted: showed first element only (plan used List.get(combined,0)) — kept both first and conceptual coverage"
metrics:
  duration: 5min
  tasks_completed: 2
  files_modified: 3
  completed_date: "2026-02-27"
---

# Quick Task 9: Update Mesh Skill with Services, Job, and List APIs

One-liner: Added service blocks (call/cast/init gen_server pattern), Job.async/await, and List.get/length/++ to the Mesh agent skill files.

## What Was Changed

### tools/skill/mesh/skills/actors/SKILL.md

Two new sections appended before the existing "See Also" block:

**Section: Services (Stateful OTP-style Processes)**
- 8 rules documenting the `service Name do init/call/cast end` pattern
- Rule 1: service block syntax
- Rule 2: init function — return type defines state type
- Rule 3: call handlers — synchronous, return `(new_state, return_value)` tuple
- Rule 4: cast handlers — asynchronous (fire-and-forget), return `new_state`
- Rule 5: `Name.start(init_args...)` spawns the service
- Rule 6: `Name.op_name(pid, args...)` for sync call invocation (snake_case)
- Rule 7: `Name.cast_op_name(pid, args...)` for async cast invocation
- Rule 8: state is private — external access only through call/cast
- Counter example (Int state, GetCount/Increment call + Reset cast) from service_counter.mpl
- Limiter example (LimitState struct state, Check call returning Bool) from service_bool_return.mpl

**Section: Job Module (Async Tasks)**
- 4 rules documenting Job.async/Job.await
- Rule 1: `Job.async(fn() -> expr end)` spawns and returns handle
- Rule 2: `Job.await(job)` blocks and returns `Result<T, String>`
- Rule 3: fire-and-collect concurrency pattern
- Rule 4: closure must take no arguments
- Example from job_async_await.mpl

### tools/skill/mesh/skills/collections/SKILL.md

**New rules in List<T> section (added after rule 13):**
- Rule 14: `List.get(list, index)` — zero-based indexing, panics if out of bounds
- Rule 15: `List.length(list)` — returns element count as Int
- Rule 16: `list1 ++ list2` — list concatenation infix operator

**New code example block** added after the existing stdlib_list_pipe_chain.mpl example:
- Indexing and length example from list_append_string.mpl (List.append + List.length + List.get)
- List concatenation example from list_concat.mpl (++ operator + List.get)

**Clarifying note added** to existing map/filter/reduce example indicating that bare `map`/`filter`/`reduce` are global aliases and `List.*` module-qualified forms are preferred in new code.

### tools/skill/mesh/SKILL.md

**Ecosystem Overview:** Added item 5:
> "5. Concurrency Utilities: Job module for async task spawning/awaiting; service blocks for stateful OTP-style gen_server processes."

**Available Sub-Skills:** Updated actors entry from:
> `skills/actors` — Actor blocks, spawn, send, receive, typed PIDs, linking, preemption

To:
> `skills/actors` — Actor blocks, spawn, send, receive, typed PIDs, services (call/cast), Job.async/await

## Decisions

1. **Service section placement:** Appended before the final "See Also" block to preserve the convention that "See Also" is the last element in actors/SKILL.md.

2. **Limiter example scope:** Simplified to show only the Check call (not SetEnabled) to keep the struct-state pattern clear without introducing Bool argument examples that would require more context.

3. **Note on bare functions:** Added as an inline comment in the existing code example rather than a separate rule, since the Global Collection Functions section already documents this distinction — avoids duplication.

4. **++ operator documentation:** Placed as rule 16 (alongside get/length) since it is a new List operation not previously documented, even though syntactically it is an infix operator.

## Commits

- `11742bbd` — feat(quick-9): document service blocks and Job module in actors sub-skill
- `ba7d4050` — feat(quick-9): add List.get/length/++ to collections sub-skill and update SKILL.md overview

## Self-Check

Files exist:
- tools/skill/mesh/skills/actors/SKILL.md: FOUND
- tools/skill/mesh/skills/collections/SKILL.md: FOUND
- tools/skill/mesh/SKILL.md: FOUND

Verification grep counts (all > 0):
1. "service Counter" in actors/SKILL.md: 1
2. "Job.async" in actors/SKILL.md: 3
3. "List.get" in collections/SKILL.md: 3
4. "List.length" in collections/SKILL.md: 2
5. "Job" in SKILL.md: 2

## Self-Check: PASSED
