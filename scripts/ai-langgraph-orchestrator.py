#!/usr/bin/env python
"""Dynamic multi-agent orchestration with LangGraph.

This script plans a task, routes subtasks across Codex/Claude/Agent,
and switches tools during execution based on dependency order.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import tempfile
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from typing_extensions import TypedDict

from langgraph.graph import END, START, StateGraph


REPO_ROOT = Path(__file__).resolve().parent.parent


class Step(TypedDict):
    id: str
    title: str
    tool: str
    execution: str
    depends_on: list[str]
    objective: str


class CompletedStep(TypedDict):
    id: str
    title: str
    tool: str
    status: str
    output: str


class OrchestratorState(TypedDict):
    task: str
    forced_tool: str
    forced_strategy: str
    plan: list[Step]
    active_steps: list[Step]
    completed_steps: list[CompletedStep]
    status: str
    iteration: int
    max_iterations: int
    log: list[str]
    verbose: bool


@dataclass
class ToolResult:
    ok: bool
    output: str
    error: str


def run_cmd(
    cmd: list[str],
    *,
    env: dict[str, str] | None = None,
    timeout_sec: int = 1800,
) -> ToolResult:
    try:
        ps_parts = " ".join("'" + part.replace("'", "''") + "'" for part in cmd)
        ps_script = (
            "$ErrorActionPreference='Stop'; "
            f"& {ps_parts}; "
            "if ($LASTEXITCODE -ne $null) { exit $LASTEXITCODE } else { exit 0 }"
        )
        proc = subprocess.run(
            ["powershell", "-NoProfile", "-Command", ps_script],
            cwd=REPO_ROOT,
            env=env,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout_sec,
            check=False,
        )
        out = (proc.stdout or "").strip()
        err = (proc.stderr or "").strip()
        if proc.returncode == 0:
            return ToolResult(ok=True, output=out, error=err)
        return ToolResult(ok=False, output=out, error=err or f"exit_code={proc.returncode}")
    except Exception as exc:  # pragma: no cover - defensive
        return ToolResult(ok=False, output="", error=str(exc))


def codex_exec(prompt: str, model: str = "gpt-5.3-codex") -> ToolResult:
    with tempfile.NamedTemporaryFile(suffix=".txt", delete=False) as tmp:
        msg_file = tmp.name
    cmd = [
        "codex",
        "exec",
        "--full-auto",
        "-m",
        model,
        "--output-last-message",
        msg_file,
        prompt,
    ]
    result = run_cmd(cmd)
    try:
        text = Path(msg_file).read_text(encoding="utf-8", errors="replace").strip()
    except Exception:
        text = ""
    finally:
        try:
            Path(msg_file).unlink(missing_ok=True)
        except Exception:
            pass
    if text:
        return ToolResult(ok=result.ok, output=text, error=result.error)
    return result


def claude_exec(prompt: str, model: str = "sonnet") -> ToolResult:
    env = os.environ.copy()
    # Local Claude auth can work even if stale ANTHROPIC_API_KEY is present.
    env.pop("ANTHROPIC_API_KEY", None)
    cmd = ["claude", "-p", "--model", model, prompt]
    return run_cmd(cmd, env=env)


def agent_exec(prompt: str, model: str = "gpt-5.2") -> ToolResult:
    cmd = ["agent", "--print", "--model", model, prompt]
    return run_cmd(cmd)


def infer_tool_for_task(task_text: str) -> str:
    lower = task_text.lower()
    code_keywords = [
        "bug",
        "error",
        "fix",
        "test",
        "build",
        "typescript",
        "python",
        "flutter",
        "api",
        "endpoint",
        "sql",
        "migration",
    ]
    analysis_keywords = [
        "architecture",
        "design",
        "tradeoff",
        "compare",
        "alternatives",
        "adr",
        "rfc",
        "roadmap",
    ]
    code_score = sum(1 for k in code_keywords if k in lower)
    analysis_score = sum(1 for k in analysis_keywords if k in lower)
    if code_score >= analysis_score + 1:
        return "codex"
    if analysis_score >= code_score + 1:
        return "claude"
    return "codex"


def extract_json_object(text: str) -> dict[str, Any] | None:
    text = text.strip()
    # Direct JSON
    try:
        obj = json.loads(text)
        if isinstance(obj, dict):
            return obj
    except Exception:
        pass

    # Extract first balanced {...}
    start = text.find("{")
    if start == -1:
        return None
    depth = 0
    end = -1
    for idx in range(start, len(text)):
        ch = text[idx]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                end = idx
                break
    if end == -1:
        return None
    try:
        obj = json.loads(text[start : end + 1])
        if isinstance(obj, dict):
            return obj
    except Exception:
        return None
    return None


def normalize_plan(raw_plan: dict[str, Any], task: str, forced_tool: str, forced_strategy: str) -> list[Step]:
    raw_steps = raw_plan.get("steps")
    if not isinstance(raw_steps, list):
        raw_steps = []

    normalized: list[Step] = []
    seen_ids: set[str] = set()
    for idx, item in enumerate(raw_steps, start=1):
        if not isinstance(item, dict):
            continue
        sid = str(item.get("id") or f"S{idx}").strip() or f"S{idx}"
        if sid in seen_ids:
            sid = f"{sid}_{idx}"
        seen_ids.add(sid)

        tool = str(item.get("tool") or "").strip().lower()
        if forced_tool != "auto":
            tool = forced_tool
        if tool not in {"codex", "claude", "agent"}:
            tool = infer_tool_for_task(f"{item.get('title', '')} {item.get('objective', '')}")

        execution = str(item.get("execution") or "").strip().lower()
        if forced_strategy != "auto":
            execution = forced_strategy
        if execution not in {"sequential", "parallel"}:
            execution = "sequential"

        depends_on_raw = item.get("depends_on")
        depends_on: list[str] = []
        if isinstance(depends_on_raw, list):
            depends_on = [str(x).strip() for x in depends_on_raw if str(x).strip()]

        title = str(item.get("title") or f"Step {idx}")
        objective = str(item.get("objective") or title)

        normalized.append(
            Step(
                id=sid,
                title=title,
                tool=tool,
                execution=execution,
                depends_on=depends_on,
                objective=objective,
            )
        )

    if not normalized:
        fallback_tool = forced_tool if forced_tool != "auto" else infer_tool_for_task(task)
        fallback_exec = forced_strategy if forced_strategy != "auto" else "sequential"
        normalized = [
            Step(
                id="S1",
                title="Solve user task",
                tool=fallback_tool,
                execution=fallback_exec,
                depends_on=[],
                objective=task,
            )
        ]

    valid_ids = {s["id"] for s in normalized}
    for s in normalized:
        s["depends_on"] = [d for d in s["depends_on"] if d in valid_ids and d != s["id"]]
    return normalized


def model_for_tool(tool: str) -> str:
    if tool == "codex":
        return "gpt-5.3-codex"
    if tool == "claude":
        return "sonnet"
    return "gpt-5.2"


def execute_tool(tool: str, prompt: str) -> ToolResult:
    if tool == "codex":
        return codex_exec(prompt, model=model_for_tool("codex"))
    if tool == "claude":
        return claude_exec(prompt, model=model_for_tool("claude"))
    return agent_exec(prompt, model=model_for_tool("agent"))


def plan_node(state: OrchestratorState) -> dict[str, Any]:
    task = state["task"]
    forced_tool = state["forced_tool"]
    forced_strategy = state["forced_strategy"]
    verbose = state.get("verbose", True)

    planner_prompt = f"""
You are an orchestration planner.
Return STRICT JSON only, no markdown, no prose.

Task:
{task}

Create an execution plan with up to 6 steps.
Use this schema exactly:
{{
  "steps": [
    {{
      "id": "S1",
      "title": "short title",
      "tool": "codex|claude|agent",
      "execution": "sequential|parallel",
      "depends_on": [],
      "objective": "what this step must produce"
    }}
  ]
}}

Rules:
- Pick tool per step:
  - codex: code edits, tests, terminal-heavy debugging
  - claude: architecture/research/spec decomposition
  - agent: second-pass validation or alternative implementation checks
- Prefer parallel only for independent steps.
- Steps must be dependency-safe.
""".strip()

    plan_result = codex_exec(planner_prompt, model="gpt-5.3-codex")
    plan_json = extract_json_object(plan_result.output)
    if not plan_json:
        plan_json = {}
    plan = normalize_plan(plan_json, task, forced_tool, forced_strategy)

    log_entry = f"[plan] generated {len(plan)} steps"
    if verbose:
        print(log_entry, flush=True)
    return {
        "plan": plan,
        "status": "running",
        "iteration": 0,
        "completed_steps": [],
        "active_steps": [],
        "log": state["log"] + [log_entry],
    }


def pick_node(state: OrchestratorState) -> dict[str, Any]:
    plan = state["plan"]
    completed_ids = {s["id"] for s in state["completed_steps"]}
    pending = [s for s in plan if s["id"] not in completed_ids]

    if not pending:
        failed = [s for s in state["completed_steps"] if s["status"] != "ok"]
        if failed:
            return {"status": "error", "active_steps": []}
        return {"status": "done", "active_steps": []}

    ready = [s for s in pending if all(dep in completed_ids for dep in s["depends_on"])]
    if not ready:
        return {"status": "error", "active_steps": [], "log": state["log"] + ["[pick] dependency deadlock"]}

    parallel_ready = [s for s in ready if s["execution"] == "parallel"]
    if len(parallel_ready) >= 2:
        active = parallel_ready
    else:
        active = [ready[0]]

    ids = ",".join(s["id"] for s in active)
    log_entry = f"[pick] active={ids}"
    if state.get("verbose", True):
        print(log_entry, flush=True)
    return {"active_steps": active, "status": "running", "log": state["log"] + [log_entry]}


def make_step_prompt(task: str, step: Step, completed: list[CompletedStep]) -> str:
    recent = completed[-3:]
    context_lines: list[str] = []
    for item in recent:
        short_output = item["output"].strip().replace("\n", " ")
        if len(short_output) > 700:
            short_output = short_output[:700] + "..."
        context_lines.append(f"- {item['id']} [{item['tool']}] {item['status']}: {short_output}")
    context = "\n".join(context_lines) if context_lines else "- none"

    return f"""
Global task:
{task}

Current subtask:
- id: {step["id"]}
- title: {step["title"]}
- objective: {step["objective"]}

Recent completed context:
{context}

Execution requirements:
1. Execute the subtask directly.
2. Use tools/files as needed.
3. Return concise result including:
   - actions performed
   - key evidence (files/tests/logs)
   - blockers (if any)
""".strip()


def run_one_step(task: str, step: Step, completed: list[CompletedStep]) -> CompletedStep:
    prompt = make_step_prompt(task, step, completed)
    primary_tool = step["tool"]
    result = execute_tool(primary_tool, prompt)

    used_tool = primary_tool
    status = "ok" if result.ok else "failed"
    output_text = result.output.strip() or result.error.strip()

    # Fallback to codex if chosen tool failed.
    if (not result.ok) and primary_tool != "codex":
        fallback = codex_exec(prompt, model="gpt-5.3-codex")
        if fallback.ok and fallback.output.strip():
            used_tool = "codex"
            status = "ok"
            output_text = fallback.output.strip()
        else:
            output_text = f"{output_text}\n\n[fallback_codex_error]\n{fallback.error.strip() or fallback.output.strip()}"

    return CompletedStep(
        id=step["id"],
        title=step["title"],
        tool=used_tool,
        status=status,
        output=output_text,
    )


def run_node(state: OrchestratorState) -> dict[str, Any]:
    active = state["active_steps"]
    if not active:
        return {"status": "error", "log": state["log"] + ["[run] no active steps"]}

    if state["iteration"] >= state["max_iterations"]:
        return {"status": "error", "log": state["log"] + ["[run] max iterations reached"]}

    task = state["task"]
    completed = list(state["completed_steps"])
    results: list[CompletedStep] = []
    verbose = state.get("verbose", True)

    if len(active) == 1:
        step = active[0]
        if verbose:
            print(f"[run] {step['id']} tool={step['tool']} mode=single", flush=True)
        results.append(run_one_step(task, step, completed))
    else:
        if verbose:
            print(
                f"[run] batch={','.join(s['id'] for s in active)} mode=parallel",
                flush=True,
            )
        with ThreadPoolExecutor(max_workers=min(4, len(active))) as pool:
            futures = {
                pool.submit(run_one_step, task, step, completed): step["id"] for step in active
            }
            for fut in as_completed(futures):
                results.append(fut.result())

    if verbose:
        for r in results:
            print(f"[done] {r['id']} status={r['status']} tool={r['tool']}", flush=True)

    return {
        "completed_steps": completed + results,
        "iteration": state["iteration"] + 1,
        "status": "running",
    }


def route_after_pick(state: OrchestratorState) -> str:
    if state["status"] in {"done", "error"}:
        return "end"
    return "run"


def build_graph():
    graph = StateGraph(OrchestratorState)
    graph.add_node("plan", plan_node)
    graph.add_node("pick", pick_node)
    graph.add_node("run", run_node)
    graph.add_edge(START, "plan")
    graph.add_edge("plan", "pick")
    graph.add_conditional_edges("pick", route_after_pick, {"run": "run", "end": END})
    graph.add_edge("run", "pick")
    return graph.compile()


def print_summary(state: OrchestratorState) -> None:
    print("", flush=True)
    print("=== Orchestration Summary ===", flush=True)
    print(f"status: {state['status']}", flush=True)
    for step in state["completed_steps"]:
        print(f"- {step['id']} [{step['tool']}] {step['status']} :: {step['title']}", flush=True)
    print("", flush=True)
    print("=== Final Outputs ===", flush=True)
    for step in state["completed_steps"]:
        print(f"\n[{step['id']}]\n{step['output']}\n", flush=True)


def collect_outputs_text(state: OrchestratorState) -> str:
    parts: list[str] = []
    for step in state["completed_steps"]:
        output = (step.get("output") or "").strip()
        if not output:
            continue
        parts.append(f"[{step['id']}] {output}")
    return "\n\n".join(parts).strip()


def run_orchestration(
    task: str,
    *,
    forced_tool: str,
    forced_strategy: str,
    max_iterations: int,
    verbose: bool,
) -> OrchestratorState:
    init_state: OrchestratorState = {
        "task": task,
        "forced_tool": forced_tool,
        "forced_strategy": forced_strategy,
        "plan": [],
        "active_steps": [],
        "completed_steps": [],
        "status": "planning",
        "iteration": 0,
        "max_iterations": max_iterations,
        "log": [],
        "verbose": verbose,
    }
    app = build_graph()
    return app.invoke(init_state)


def build_chat_task(
    history: list[tuple[str, str]],
    user_message: str,
    *,
    history_turns: int,
) -> str:
    sliced = history[-(history_turns * 2) :]
    lines: list[str] = []
    for role, text in sliced:
        compact = " ".join((text or "").strip().split())
        if len(compact) > 900:
            compact = compact[:900] + "..."
        label = "User" if role == "user" else "Assistant"
        lines.append(f"{label}: {compact}")
    context = "\n".join(lines) if lines else "User: (start of session)"

    return f"""
You are running in interactive chat orchestration mode.
The assistant must support free conversation and execution requests.

Conversation history:
{context}

Current user message:
{user_message}

Rules:
- Decide from the current message whether this is:
  1) question/discussion only, or
  2) request to execute actions in workspace.
- For question/discussion only: do not edit files or run unnecessary commands.
- For execution requests: perform changes and validations as needed.
- Keep response concise and practical, aligned with the user's language.
""".strip()


def print_chat_help() -> None:
    print("", flush=True)
    print("Chat commands:", flush=True)
    print("  /help                Show this help", flush=True)
    print("  /exit or /quit       Exit chat", flush=True)
    print("  /reset               Clear conversation context", flush=True)
    print("  /tool <value>        Set tool: auto|codex|claude|agent", flush=True)
    print("  /strategy <value>    Set strategy: auto|sequential|parallel", flush=True)
    print("  /status              Show current chat settings", flush=True)
    print("", flush=True)


def chat_loop(
    *,
    forced_tool: str,
    forced_strategy: str,
    max_iterations: int,
    history_turns: int,
    initial_message: str,
) -> int:
    current_tool = forced_tool
    current_strategy = forced_strategy
    history: list[tuple[str, str]] = []
    queue: list[str] = []
    if initial_message.strip():
        queue.append(initial_message.strip())

    print(
        f"[chat] orchestrate mode active (tool={current_tool}, strategy={current_strategy}, max_iterations={max_iterations})",
        flush=True,
    )
    print("Type /help for commands.", flush=True)

    while True:
        if queue:
            user_text = queue.pop(0)
            print(f"\nYou> {user_text}", flush=True)
        else:
            try:
                user_text = input("\nYou> ").strip()
            except EOFError:
                print("\n[chat] EOF received, exiting.", flush=True)
                return 0
            except KeyboardInterrupt:
                print("\n[chat] Interrupted, exiting.", flush=True)
                return 130

        if not user_text:
            continue

        lower = user_text.lower()
        if lower in {"/exit", "/quit"}:
            print("[chat] Bye.", flush=True)
            return 0
        if lower == "/help":
            print_chat_help()
            continue
        if lower == "/reset":
            history.clear()
            print("[chat] Context reset.", flush=True)
            continue
        if lower == "/status":
            print(f"[chat] tool={current_tool} strategy={current_strategy}", flush=True)
            continue
        if lower.startswith("/tool "):
            candidate = lower.split(maxsplit=1)[1].strip()
            if candidate in {"auto", "codex", "claude", "agent"}:
                current_tool = candidate
                print(f"[chat] tool set to {current_tool}", flush=True)
            else:
                print("[chat] Invalid tool. Use auto|codex|claude|agent.", flush=True)
            continue
        if lower.startswith("/strategy "):
            candidate = lower.split(maxsplit=1)[1].strip()
            if candidate in {"auto", "sequential", "parallel"}:
                current_strategy = candidate
                print(f"[chat] strategy set to {current_strategy}", flush=True)
            else:
                print("[chat] Invalid strategy. Use auto|sequential|parallel.", flush=True)
            continue

        task = build_chat_task(history, user_text, history_turns=history_turns)
        final_state = run_orchestration(
            task,
            forced_tool=current_tool,
            forced_strategy=current_strategy,
            max_iterations=max_iterations,
            verbose=True,
        )
        print_summary(final_state)

        assistant_text = collect_outputs_text(final_state)
        if not assistant_text:
            assistant_text = f"(status={final_state['status']})"

        history.append(("user", user_text))
        history.append(("assistant", assistant_text))


def main() -> int:
    parser = argparse.ArgumentParser(description="LangGraph multi-agent orchestrator")
    parser.add_argument("task", nargs="*", help="Task to execute")
    parser.add_argument(
        "--tool",
        default="auto",
        choices=["auto", "codex", "claude", "agent"],
        help="Force a single tool for all steps",
    )
    parser.add_argument(
        "--strategy",
        default="auto",
        choices=["auto", "sequential", "parallel"],
        help="Force execution style",
    )
    parser.add_argument(
        "--max-iterations",
        type=int,
        default=8,
        help="Safety cap for orchestration loop",
    )
    parser.add_argument(
        "--chat",
        action="store_true",
        help="Start interactive orchestration chat",
    )
    parser.add_argument(
        "--chat-history-turns",
        type=int,
        default=6,
        help="How many recent user/assistant turns to keep in chat context",
    )
    args = parser.parse_args()

    task = " ".join(args.task).strip()
    if args.chat:
        return chat_loop(
            forced_tool=args.tool,
            forced_strategy=args.strategy,
            max_iterations=args.max_iterations,
            history_turns=max(1, args.chat_history_turns),
            initial_message=task,
        )

    if not task:
        print("Task is empty.", flush=True)
        return 1

    final_state = run_orchestration(
        task,
        forced_tool=args.tool,
        forced_strategy=args.strategy,
        max_iterations=args.max_iterations,
        verbose=True,
    )
    print_summary(final_state)
    return 0 if final_state["status"] == "done" else 1


if __name__ == "__main__":
    raise SystemExit(main())
