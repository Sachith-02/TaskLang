# TaskLang++

> A domain-specific language for task scheduling and automation

![Build](https://img.shields.io/badge/build-passing-brightgreen)
![Language](https://img.shields.io/badge/language-C-blue)
![Tools](https://img.shields.io/badge/tools-Flex%20%2B%20Bison-lightgrey)
![Tests](https://img.shields.io/badge/tests-20%2F20-yellow)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

TaskLang++ is a declarative, formally-defined DSL for expressing task scheduling workflows. It supports time-based scheduling, inter-task dependencies, and conditional execution — compiled via a Flex lexer and Bison parser into a validated execution plan.

---

## Features

- **Time-based scheduling** — `EVERY DAY`, `EVERY WEEK ON <day>`, or one-shot `AT HH:MM` with lexer-level time validation
- **Task dependencies** — `AFTER` / `BEFORE` / `DEPENDS` with circular dependency detection (DFS)
- **Conditional execution** — `IF success` / `IF failure` guards on downstream tasks
- **Semantic validation** — duplicate names, undefined dependencies, and cycles caught at parse time
- **Topological execution** — tasks execute in correct dependency order (Kahn's algorithm)
- **Helpful errors** — line-numbered lexical, syntax, and semantic error messages

---

## Example

```
# Daily backup pipeline
TASK backupDB {
    RUN "backup.sh"
    EVERY DAY AT 02:00
}

TASK sendReport {
    RUN "report.py"
    AFTER backupDB
    IF success
}

TASK cleanup {
    RUN "cleanup.sh"
    EVERY WEEK ON SUNDAY AT 03:00
}
```

**Output:**

```
Parsing TaskLang++ input...

--- EXECUTION START ---

Executing Task: backupDB
  Script: "backup.sh"
  Schedule: EVERY DAY AT 02:00

Executing Task: cleanup
  Script: "cleanup.sh"
  Schedule: EVERY WEEK ON SUNDAY AT 03:00

Executing Task: sendReport
  Script: "report.py"
  Schedule: (none)
  Depends on: backupDB
  Condition: success

--- EXECUTION COMPLETE ---
```

---

## Quick Start

**Prerequisites:** `flex`, `bison`, `gcc`, `make`, `python3`

```bash
# Clone
git clone https://github.com/your-username/tasklang-plus-plus
cd tasklang-plus-plus

# Build
make

# Run a program
./tasklang < tests/valid_02.tl

# Run all 20 tests
python3 run_tests.py
```

---

## Project Structure

```
tasklang-plus-plus/
├── lexer.l           # Flex lexer — tokenises TaskLang++ source
├── parser.y          # Bison parser — grammar, semantics, execution simulation
├── Makefile          # build / run / test / clean targets
├── run_tests.py      # automated test runner (Python 3)
└── tests/
    ├── valid_01.tl … valid_10.tl     # 10 valid programs
    └── invalid_01.tl … invalid_10.tl # 10 invalid programs (correctly rejected)
```

---

## Language Reference

### Task definition

```
TASK <name> {
    RUN "<script>"
    [schedule]
    [AFTER <taskName>]
    [IF success | IF failure]
}
```

### Scheduling forms

| Syntax | Meaning |
|--------|---------|
| `EVERY DAY AT HH:MM` | Run daily at a fixed time |
| `EVERY WEEK ON <day> AT HH:MM` | Run weekly on a named day |
| `AT HH:MM` | Run once at the specified time |

Days: `MONDAY` `TUESDAY` `WEDNESDAY` `THURSDAY` `FRIDAY` `SATURDAY` `SUNDAY`

### Dependencies

| Keyword | Meaning |
|---------|---------|
| `AFTER taskName` | This task runs after the named task |
| `BEFORE taskName` | This task runs before the named task |
| `DEPENDS taskName` | Shorthand for `AFTER` |

Multiple dependency declarations are allowed in one task.

### Tokens

| Token | Pattern | Description |
|-------|---------|-------------|
| `TASK` | `TASK` | Begins a task definition |
| `RUN` | `RUN "..."` | Command to execute |
| `EVERY` | `EVERY` | Recurring schedule keyword |
| `AT` | `AT HH:MM` | Time specifier (24-hour) |
| `AFTER` | `AFTER name` | Post-dependency |
| `IF` | `IF success\|failure` | Conditional execution |
| `TIME_VAL` | `([01][0-9]\|2[0-3]):[0-5][0-9]` | Valid 24-hour time |
| `STRING_LIT` | `"[^"\n]*"` | Quoted string |
| `IDENTIFIER` | `[a-zA-Z_][a-zA-Z0-9_]*` | Task name |

Comments start with `#` and extend to end of line.

---

## Error Handling

The compiler reports three categories of errors:

- **Lexical errors** — unrecognised characters, invalid time formats (e.g. `08:75`), unterminated strings
- **Syntax errors** — missing braces, wrong keyword order, unquoted RUN operands
- **Semantic errors** — missing `RUN` statement, undefined dependency target, duplicate task name, circular dependency

Example:

```
[Semantic Error] Circular dependency detected: 'taskB' -> 'taskA' -> ... -> 'taskB'
[Result] Parsing FAILED with 1 error(s).
```

---

## Test Coverage

| Category | Cases | Scenarios |
|----------|-------|-----------|
| Valid programs | 10 | Daily/weekly/AT schedules, diamond dependency graph, failure conditions, comments, edge-case identifiers |
| Invalid programs | 10 | Missing RUN, bad time format, undefined dep, circular dep (2-way and 3-way), duplicate name, missing brace, unquoted string, unterminated string |

All 20 tests pass with correct exit codes (0 for valid, 1 for invalid).

---

## Build Targets

```bash
make          # build the tasklang binary
make run      # run tests/valid_01.tl
make clean    # remove all generated files
```

---

## Assignment Context

Built for **SE2052 – Programming Paradigms** (Y2 S2, BSc Hons Computer Science). Implements a full compiler front-end: Flex lexer + Bison parser with semantic validation and topological execution simulation.

---

## License

MIT
