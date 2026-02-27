---
plan: 9
type: execute
wave: 1
depends_on: []
files_modified:
  - tools/skill/mesh/skills/actors/SKILL.md
  - tools/skill/mesh/skills/collections/SKILL.md
  - tools/skill/mesh/SKILL.md
autonomous: true
must_haves:
  truths:
    - "Service blocks (call/cast/init pattern) are documented with working examples"
    - "Job.async/Job.await are documented with a working example"
    - "List.get, List.length, and ++ operator are documented in collections sub-skill"
    - "SKILL.md ecosystem overview mentions services and Job module"
  artifacts:
    - path: "tools/skill/mesh/skills/actors/SKILL.md"
      provides: "Service blocks and Job module documentation"
      contains: "service"
    - path: "tools/skill/mesh/skills/collections/SKILL.md"
      provides: "List.get, List.length, ++ operator"
      contains: "List.get"
    - path: "tools/skill/mesh/SKILL.md"
      provides: "Updated ecosystem overview"
      contains: "Job"
  key_links:
    - from: "tools/skill/mesh/SKILL.md"
      to: "tools/skill/mesh/skills/actors/SKILL.md"
      via: "Ecosystem Overview and Available Sub-Skills references"
---

<objective>
Update the tools/skill/mesh/ skill to document language features added or discovered since Phase 121 (when the skill was first created), as part of the v12.0 milestone.

Purpose: The skill is the primary reference for AI agents working with Mesh code. Missing primitives cause agents to write incorrect Mesh programs. Three gaps were found by auditing E2E tests against skill coverage.

Output: Updated SKILL.md files that document service blocks, Job.async/await, List.get, List.length, and the ++ list concat operator.
</objective>

<execution_context>
@/Users/sn0w/.claude/get-shit-done/workflows/execute-plan.md
@/Users/sn0w/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@tools/skill/mesh/SKILL.md
@tools/skill/mesh/skills/actors/SKILL.md
@tools/skill/mesh/skills/collections/SKILL.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Document service blocks and Job module in actors sub-skill</name>
  <files>tools/skill/mesh/skills/actors/SKILL.md</files>
  <action>
Append two new sections to tools/skill/mesh/skills/actors/SKILL.md — do NOT remove or alter existing content.

**Section: Services (Stateful OTP-style Processes)**

Add after the existing "See Also" block:

```
## Services (Stateful OTP-style Processes)

Rules:
1. `service Name do init ... call ... cast ... end` defines a stateful, message-handling process (gen_server pattern).
2. `fn init(params...) -> State do ... end` — initializes state; return type defines the state type.
3. `call OpName(params) :: ReturnType do |state| ... end` — synchronous handler; body returns `(new_state, return_value)`.
4. `cast OpName(params) do |state| ... end` — asynchronous handler (fire-and-forget); body returns just `new_state`.
5. `Name.start(init_args...)` — spawns the service actor and returns its Pid.
6. `Name.op_name(pid, args...)` — calls an operation synchronously (snake_case of the defined OpName).
7. `Name.cast_op_name(pid, args...)` — fires a cast operation asynchronously (no return value captured).
8. State is private — external code only interacts through call/cast operations.

Code example (from tests/e2e/service_counter.mpl):
```mesh
service Counter do
  fn init(start_val :: Int) -> Int do
    start_val
  end

  call GetCount() :: Int do |count|
    (count, count)
  end

  call Increment(amount :: Int) :: Int do |count|
    (count + amount, count + amount)
  end

  cast Reset() do |_count|
    0
  end
end

fn main() do
  let pid = Counter.start(10)
  let c1 = Counter.get_count(pid)    # sync call, returns Int
  println("${c1}")                   # 10
  let c2 = Counter.increment(pid, 5) # sync call, returns Int
  println("${c2}")                   # 15
  Counter.reset(pid)                 # async cast, no return
  let c3 = Counter.get_count(pid)    # 0
  println("${c3}")
end
```

Code example with struct state (from tests/e2e/service_bool_return.mpl):
```mesh
struct LimitState do
  count :: Int
  max :: Int
end

service Limiter do
  fn init(max :: Int) -> LimitState do
    LimitState { count: 0, max: max }
  end

  call Check() :: Bool do |state|
    if state.count >= state.max do
      (state, false)
    else
      let new_state = LimitState { count: state.count + 1, max: state.max }
      (new_state, true)
    end
  end
end

fn main() do
  let pid = Limiter.start(2)
  let ok = Limiter.check(pid)   # true (first call)
  println("${ok}")
end
```
```

**Section: Job Module (Async Tasks)**

```
## Job Module (Async Tasks)

Rules:
1. `Job.async(fn() -> expr end)` — spawns a function on the actor runtime and returns a Job handle immediately.
2. `Job.await(job) -> Result<T, String>` — blocks until the job completes and returns `Ok(result)` or `Err(message)` on panic.
3. Use for fire-and-collect concurrency: submit multiple jobs, then await each.
4. The closure passed to `Job.async` must take no arguments: `fn() -> ... end`.

Code example (from tests/e2e/job_async_await.mpl):
```mesh
fn main() do
  let job = Job.async(fn() -> 42 end)
  let result = Job.await(job)
  case result do
    Ok(val) -> println("${val}")   # 42
    Err(msg) -> println(msg)
  end
end
```
```

The final "See Also" block should remain at the end of the file. Preserve all existing content above the new sections.
  </action>
  <verify>
    <automated>grep -l "service Counter" /Users/sn0w/Documents/dev/snow/tools/skill/mesh/skills/actors/SKILL.md && grep -l "Job.async" /Users/sn0w/Documents/dev/snow/tools/skill/mesh/skills/actors/SKILL.md</automated>
    <manual>Confirm services and Job sections are present and readable</manual>
  </verify>
  <done>actors/SKILL.md contains a "Services (Stateful OTP-style Processes)" section with call/cast/init rules and the Counter and Limiter examples, plus a "Job Module (Async Tasks)" section with Job.async/Job.await rules and example.</done>
</task>

<task type="auto">
  <name>Task 2: Add List.get, List.length, and ++ operator to collections sub-skill and SKILL.md overview</name>
  <files>tools/skill/mesh/skills/collections/SKILL.md</files>
  <action>
**In tools/skill/mesh/skills/collections/SKILL.md**, make these targeted additions:

1. In the "List&lt;T&gt;" section, add the following rules after rule 13 (List.flat_map):
   - Rule 14: `List.get(list, index)` — returns element at zero-based index (panics if out of bounds).
   - Rule 15: `List.length(list)` — returns the number of elements as Int.
   - Rule 16: `list1 ++ list2` — concatenates two lists into a new list (the `++` infix operator).

2. Update the code example for List to use `List.get` and `++` so it reflects real test patterns. Append a new brief code example after the existing list pipe chain example:

```mesh
# Indexing and length (from tests/e2e/list_append_string.mpl):
let ss = ["hello"]
let ss = List.append(ss, "world")
let len = List.length(ss)       # 2
let second = List.get(ss, 1)    # "world"
println("${len}")
println(second)

# List concatenation with ++ (from tests/e2e/list_concat.mpl):
let a = [1, 2]
let b = [3, 4]
let combined = a ++ b           # [1, 2, 3, 4]
let first = List.get(combined, 0)  # 1
```

Also update the existing incorrect code example: the example currently shows bare `map`/`filter`/`reduce` as the primary example for List — add a note that `List.map`, `List.filter` are the module-qualified preferred forms, and the bare forms (`map`, `filter`, `reduce`) are global aliases.

**In tools/skill/mesh/SKILL.md**, make these targeted additions:

1. In the "Ecosystem Overview" section, add a new item:
   `5. Concurrency Utilities: Job module for async task spawning/awaiting; service blocks for stateful OTP-style gen_server processes.`
   (Shift the existing item 5 if it exists, or just append as item 5.)

2. In the "Available Sub-Skills" list in SKILL.md, the actors entry already covers actors — no change needed since services are documented inside actors/SKILL.md. However, update the actors entry description slightly:
   Current: `skills/actors` — Actor blocks, spawn, send, receive, typed PIDs, linking, preemption`
   Update to: `skills/actors` — Actor blocks, spawn, send, receive, typed PIDs, services (call/cast), Job.async/await`
  </action>
  <verify>
    <automated>grep -c "List.get" /Users/sn0w/Documents/dev/snow/tools/skill/mesh/skills/collections/SKILL.md && grep -c "List.length" /Users/sn0w/Documents/dev/snow/tools/skill/mesh/skills/collections/SKILL.md && grep "Job" /Users/sn0w/Documents/dev/snow/tools/skill/mesh/SKILL.md</automated>
    <manual>Confirm List.get/length/++ are in rules, SKILL.md ecosystem overview mentions services and Job</manual>
  </verify>
  <done>collections/SKILL.md has List.get, List.length, and ++ operator as documented rules with examples. SKILL.md ecosystem overview mentions the Job module and service blocks. The actors sub-skill entry in SKILL.md mentions services and Job.async/await.</done>
</task>

</tasks>

<verification>
After both tasks:
1. grep "service Counter" tools/skill/mesh/skills/actors/SKILL.md — must match
2. grep "Job.async" tools/skill/mesh/skills/actors/SKILL.md — must match
3. grep "List.get" tools/skill/mesh/skills/collections/SKILL.md — must match
4. grep "List.length" tools/skill/mesh/skills/collections/SKILL.md — must match
5. grep "Job" tools/skill/mesh/SKILL.md — must match
6. All existing skill content is preserved (no deletions of prior documented features)
</verification>

<success_criteria>
- Service blocks are fully documented: init/call/cast pattern, (new_state, return_value) tuple syntax, TypeName.start() / TypeName.op_name() calling conventions
- Job.async/Job.await are documented with a runnable example
- List.get(list, index), List.length(list), and list1 ++ list2 are in the List rules with examples
- SKILL.md mentions services and Job in the ecosystem overview
- All existing skill content preserved unchanged
</success_criteria>

<output>
After completion, create `.planning/quick/9-update-the-tools-skill-mesh-skill-with-t/9-SUMMARY.md` with:
- What was changed in each skill file
- The specific rules/sections added
- Any decisions made about placement/organization
</output>
