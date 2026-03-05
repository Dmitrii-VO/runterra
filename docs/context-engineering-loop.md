# Context Engineering Loop (Runterra)

## Зачем это нужно

Для Runterra (monorepo: `backend/`, `mobile/`, `admin/`) длинные агентные сессии быстро теряют фокус.  
Рабочий цикл ниже фиксирует состояние вне чата и снижает деградацию качества при росте контекста.

Основа:
- статья Habr про context engineering и практики `PLAN/TODO/DECISIONS/EVIDENCE`
- Claude Code docs: loop `gather context -> take action -> verify -> repeat`
- рекомендации по управлению контекстом (`/clear`, чеклисты, subagents)
- подтверждение эффекта "context rot" и потерь на длинных/шумных контекстах

## Контракт состояния (durable state)

Локальные (gitignored) файлы сессии в корне:
- `PLAN.md` — цель, границы, текущий этап, следующий шаг
- `TODO.md` — атомарные шаги и прогресс
- `DECISIONS.md` — решения и rationale
- `EVIDENCE.md` — факты из кода/логов/тестов (без лишнего шума)
- `RESTORE.md` — авто-пакет для быстрого восстановления после `/compact`/`/clear`

## Оптимальный loop для проекта

1. Start
- Запуск: `npm run ctx:start -- "<task>"`.
- Формулируем задачу в одну строку и фиксируем границы изменений.

2. Gather (JIT)
- Читаем только нужное: до 5 файлов за итерацию, ~200 строк на файл.
- Каждый факт фиксируем в `EVIDENCE.md`, не в длинном чате.

3. Plan small
- Дробим работу в `TODO.md` на небольшие проверяемые шаги.
- Под каждый шаг заранее определяем проверку (test/analyze/build).

4. Execute + Verify
- Выполняем один шаг, сразу валидируем, обновляем `EVIDENCE.md`.
- Если решение меняет поведение/архитектуру, записываем в `DECISIONS.md`.

5. Prune
- Регулярно убираем шум: `npm run ctx:prune`.
- Полные логи храним в `logs/`, в контекст не тянем.

6. Compact / Restore
- Перед `/compact`: `npm run ctx:checkpoint` (или auto через hook).
- После `/compact`/`/clear`: `npm run ctx:restore`.
- Восстанавливаемся по `RESTORE.md`, без повторного bulk-reading.

7. Done
- Закрытие сессии: `npm run ctx:done` (архив в `.tmp/context-loop/`).
- Далее обновляем `docs/progress.md` и связанные docs при изменении поведения.

## Правила качества контекста

- Один активный таск за сессию.
- Если задача ушла в другую область monorepo, лучше `/clear` + новая сессия.
- "Сигнал > шум": в `EVIDENCE.md` только проверяемые факты.
- Для исследовательских/параллельных веток использовать subagents, а в основной контекст возвращать только выводы.
- Если возникает "сложная ловушка" (агент начинает усложнять), вернуться к минимальному изменению и переписать `Next Action` в `PLAN.md`.

## Быстрые команды

```powershell
npm run ctx:start -- "Короткое описание задачи"
npm run ctx:plan
npm run ctx:checkpoint
npm run ctx:restore
npm run ctx:prune
npm run ctx:done
```

Если сессия уже активна, `ctx:start` остановится; для явной перезаписи используйте `--force`.

## Источники

- Habr: https://habr.com/ru/articles/1004994/
- Claude Code docs (how it works): https://code.claude.com/docs/en/how-claude-code-works
- Claude Code docs (best practices): https://www.anthropic.com/engineering/claude-code-best-practices
- Claude Code issue on memory/compaction: https://github.com/anthropics/claude-code/issues/26061
- Context rot paper: https://arxiv.org/html/2502.05795v1
