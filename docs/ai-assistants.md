# AI Assistants (Codex / Claude / Agent)

## Quick start

From repo root:

```powershell
npm run ai:check
npm run ai:auto -- "Fix backend auth bug and add tests"
```

If all checks are green, launch any assistant:

```powershell
npm run ai:auto -- "Fix backend auth bug and add tests"
npm run ai:codex
npm run ai:claude
npm run ai:agent
```

`ai:auto` picks tool + model automatically and injects execution policy
(parallel or sequential) based on your task text.

Now default mode is `orchestrate`: LangGraph builds a multi-step plan and can
switch between `codex`, `claude`, and `agent` during execution.

For interactive orchestrate chat (question -> question -> execution with
automatic tool/model switching per step), use:

```powershell
npm run ai:auto:chat
npm run ai:auto:chat -- tool=claude "Design-heavy session for auth"
npm run ai:auto:chat -- tool=codex "Backend bugfix session"
```

**Чтобы оркестратор мог править файлы (не read-only):** запускайте команду **вручную в терминале** (Terminal → New Terminal, затем `npm run ai:auto:chat`). Не запускайте её через кнопку «Run» в чате Cursor — в чате уже зафиксирован `sandbox_mode=read-only`, и на лету он не переключается; для записи в репозиторий нужна новая сессия, где команда выполняется в обычном терминале.

`ai:auto:chat` opens a LangGraph orchestration chat loop. Each user turn is
planned and executed in orchestrate mode, and the planner can switch between
`codex`, `claude`, and `agent` by step when `tool=auto`.

Inside chat, commands are available:

```text
/help
/status
/tool auto|codex|claude|agent
/strategy auto|sequential|parallel
/reset
/exit
```

For npm on Windows, use plain tokens (not `--print`) for options:

```powershell
npm run ai:auto -- print "Reply exactly: OK"
npm run ai:auto -- print strategy=parallel "Compare alternatives for caching"
npm run ai:auto -- print tool=claude "Design ADR for auth"
npm run ai:auto -- mode=single "Force old single-agent behavior"
```

## Passing prompt/flags directly

```powershell
powershell -ExecutionPolicy Bypass -File scripts/ai-assistant.ps1 codex exec "Reply OK"
powershell -ExecutionPolicy Bypass -File scripts/ai-assistant.ps1 claude -p "Reply OK"
powershell -ExecutionPolicy Bypass -File scripts/ai-assistant.ps1 agent --print "Reply OK"
powershell -ExecutionPolicy Bypass -File scripts/ai-auto.ps1 --print "Compare 3 backend caching approaches"
```

## Notes

- `scripts/ai-assistant.ps1` temporarily removes `ANTHROPIC_API_KEY` only for Claude launch in this shell invocation. This avoids `Invalid API key` failures when a stale global key exists.
- `scripts/ai-auto.ps1` routes requests by heuristics:
  - `mode=orchestrate` (default): dynamic multi-step handoff between agents via LangGraph.
  - `mode=chat`: interactive LangGraph chat loop with the same orchestrator.
  - `mode=single`: previous behavior, choose one agent for the full task.
  - coding-heavy tasks -> `codex` + `gpt-5.3-codex`
  - architecture/research-heavy tasks -> `claude` + `sonnet|opus`
  - mixed/default tasks -> `codex` (for reliability); use `--tool agent` to force Cursor Agent
- Codex uses your existing `codex login` state.
- Agent uses your existing `agent login` state.
