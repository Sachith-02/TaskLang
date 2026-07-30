# TaskLang++

TaskLang++ is a small domain-specific language for task scheduling and automation workflows. It was built for the SE2052 Programming Paradigms assignment using Flex for lexical analysis and Bison for parsing.

The language lets a user describe tasks, script commands, time or event schedules, dependencies, and simple success/failure conditions. The interpreter validates the program and simulates the order in which tasks would execute. It does not run real operating-system commands.

## Project Overview

TaskLang++ focuses on a common automation pattern:

> Run this script at this time or event, but only after the required tasks have completed.

The project demonstrates:

- DSL scope definition for task scheduling and automation
- tokenization with Flex
- grammar design with Bison
- syntax validation and semantic validation
- dependency graph handling
- automated testing with valid and invalid programs
- readable output for accepted programs and clear errors for rejected programs

## Assignment Mapping

| Rubric Area | How TaskLang++ Addresses It |
| --- | --- |
| DSL Design | Defines a focused scheduling language with readable task, schedule, dependency, and condition syntax. |
| Grammar | Provides EBNF and BNF grammar for all supported constructs. |
| Lexer | Uses Flex rules for keywords, identifiers, strings, valid/invalid times, comments, and lexical errors. |
| Parser | Uses Bison rules for task definitions, statements, schedules, dependencies, and conditions. |
| Integration and Execution | Builds with `make`, validates programs, resolves dependencies, and prints simulated execution order. |
| Testing | Includes 15 valid tests and 25 invalid tests, plus `make test` and `run_tests.py`. |
| Reflection | Report draft explains design trade-offs, parser conflicts, semantic validation, and future work. |

## DSL Scope

Supported task features:

- named task definitions using `TASK name { ... }`
- exactly one `RUN "script"` statement per task
- optional time-based schedule
- optional event-based schedule
- dependencies between tasks
- optional `IF success` or `IF failure` condition

Supported schedules:

- `EVERY DAY`
- `EVERY DAY AT HH:MM`
- `EVERY WEEK ON <DAY> AT HH:MM`
- `AT HH:MM`
- `WHEN <eventName>`

Supported dependencies:

- `AFTER taskName`
- `BEFORE taskName`
- `DEPENDS taskName`
- `DEPENDS ON taskName`

Supported conditions:

- `IF success`
- `IF failure`

Design assumptions:

- Every task must have exactly one `RUN`.
- A task may have at most one schedule.
- A task may have at most one condition.
- A condition must refer to a task dependency, so conditional tasks need at least one dependency.
- `BEFORE B` means task `B` depends on the current task.
- Scripts are printed for simulation only; they are not executed.

## Why a DSL Is Useful for Task Scheduling

Task scheduling has a small, repeated vocabulary: task names, scripts, times, events, dependencies, and success or failure conditions. A DSL makes this domain easier to read than a general-purpose program with many function calls or configuration objects.

For example:

```tl
TASK sendReport {
    RUN "report.py"
    AFTER backupDB
    IF success
}
```

This says directly what the workflow means. The compiler can also catch domain-specific mistakes such as invalid times, missing scripts, duplicate schedules, undefined dependencies, and circular workflows.

## Token Table

| Token | Lexeme or Pattern | Purpose |
| --- | --- | --- |
| `TASK` | `TASK` | Starts a task definition. |
| `RUN` | `RUN` | Defines the script command. |
| `EVERY` | `EVERY` | Starts a recurring schedule. |
| `DAY` | `DAY` | Daily schedule keyword. |
| `WEEK` | `WEEK` | Weekly schedule keyword. |
| `ON` | `ON` | Used in weekly schedules and `DEPENDS ON`. |
| `AT` | `AT` | Time schedule keyword. |
| `WHEN` | `WHEN` | Event-based schedule keyword. |
| `AFTER` | `AFTER` | Current task depends on another task. |
| `BEFORE` | `BEFORE` | Another task depends on the current task. |
| `DEPENDS` | `DEPENDS` | Dependency keyword. |
| `IF` | `IF` | Starts a condition. |
| `SUCCESS` | `success` | Success condition. |
| `FAILURE` | `failure` | Failure condition. |
| `MONDAY` to `SUNDAY` | day names | Weekly schedule day. |
| `LBRACE` | `{` | Opens a task block. |
| `RBRACE` | `}` | Closes a task block. |
| `TIME_VAL` | `HH:MM` from `00:00` to `23:59` | Valid 24-hour time. |
| `INVALID_TIME` | time-like invalid values such as `08:75` | Allows clear invalid-time messages. |
| `STRING_LIT` | `"..."` | Quoted script name or command. |
| `IDENTIFIER` | `[A-Za-z_][A-Za-z0-9_]*` | Task names and event names. |

Keywords are listed before identifiers in `lexer.l`, so reserved words are tokenized correctly.

## EBNF Grammar

```ebnf
program       = task_definition, { task_definition } ;

task_definition
              = "TASK", identifier, "{", { statement }, "}" ;

statement     = run_statement
              | schedule_statement
              | dependency_statement
              | condition_statement ;

run_statement = "RUN", string_literal ;

schedule_statement
              = "EVERY", "DAY"
              | "EVERY", "DAY", "AT", time
              | "EVERY", "WEEK", "ON", day_of_week, "AT", time
              | "AT", time
              | "WHEN", identifier ;

dependency_statement
              = "AFTER", identifier
              | "BEFORE", identifier
              | "DEPENDS", identifier
              | "DEPENDS", "ON", identifier ;

condition_statement
              = "IF", condition ;

condition     = "success" | "failure" ;

day_of_week   = "MONDAY" | "TUESDAY" | "WEDNESDAY" | "THURSDAY"
              | "FRIDAY" | "SATURDAY" | "SUNDAY" ;
```

## BNF Grammar

```bnf
<program> ::= <task-list>

<task-list> ::= <task-definition>
              | <task-list> <task-definition>

<task-definition> ::= TASK IDENTIFIER LBRACE <task-body> RBRACE

<task-body> ::= <statement-list>
              | empty

<statement-list> ::= <statement>
                   | <statement-list> <statement>

<statement> ::= <run-statement>
              | <schedule-statement>
              | <dependency-statement>
              | <condition-statement>

<run-statement> ::= RUN STRING_LIT

<schedule-statement> ::= <schedule-expr>

<schedule-expr> ::= EVERY DAY
                  | EVERY DAY AT TIME_VAL
                  | EVERY WEEK ON <day-of-week> AT TIME_VAL
                  | AT TIME_VAL
                  | WHEN IDENTIFIER

<dependency-statement> ::= AFTER IDENTIFIER
                         | BEFORE IDENTIFIER
                         | DEPENDS IDENTIFIER
                         | DEPENDS ON IDENTIFIER

<condition-statement> ::= IF <condition-clause>

<condition-clause> ::= SUCCESS
                     | FAILURE

<day-of-week> ::= MONDAY
                | TUESDAY
                | WEDNESDAY
                | THURSDAY
                | FRIDAY
                | SATURDAY
                | SUNDAY
```

The implementation includes an empty-program parser rule only to print a clear error. Empty input is treated as invalid by the DSL.

## Build Instructions

Requirements:

- Flex
- Bison 3 or newer
- `gcc` or `clang`
- `make`
- `python3` for the optional Python test runner

Build:

```sh
make
```

Clean and rebuild:

```sh
make clean
make
```

## Run Instructions

Run one TaskLang++ program:

```sh
./tasklang < tests/valid_01.tl
```

Run the demo:

```sh
make demo
```

The demo shows a simple daily task, a workflow with a dependency and condition, and an event-based `WHEN` schedule.

## Test Instructions

Run the full test suite:

```sh
make test
```

Run one or more named test cases:

```sh
make test valid_01
make test valid_01 valid_02 invalid_01
```

Run the optional Python test runner:

```sh
python3 run_tests.py
```

Both test runners execute the selected `tests/valid_*.tl` and
`tests/invalid_*.tl` files. Valid programs must exit with code `0`; invalid
programs must be cleanly rejected with code `1`. Crashes and other unexpected
exit codes fail the test suite.

## Test Coverage Matrix

| Requirement | Covered By |
| --- | --- |
| Simple daily task | `tests/valid_01.tl` |
| `EVERY DAY` without `AT` | `tests/valid_15.tl` |
| `EVERY DAY AT` time | `tests/valid_01.tl`, `tests/valid_02.tl` |
| `EVERY WEEK ON` day `AT` time | `tests/valid_03.tl` |
| One-time `AT` schedule | `tests/valid_06.tl`, `tests/valid_09.tl` |
| `AFTER` dependency | `tests/valid_04.tl`, `tests/valid_07.tl` |
| `BEFORE` dependency | `tests/valid_12.tl`, `tests/valid_13.tl` |
| `DEPENDS` and `DEPENDS ON` | `tests/valid_08.tl`, `tests/valid_11.tl` |
| `IF success` | `tests/valid_02.tl`, `tests/valid_11.tl` |
| `IF failure` | `tests/valid_05.tl` |
| Multiple dependencies | `tests/valid_07.tl` |
| Dependency chain | `tests/valid_04.tl`, `tests/valid_13.tl` |
| `WHEN` event schedule | `tests/valid_14.tl` |
| Comments and whitespace | `tests/valid_10.tl` |
| Empty input rejected | `tests/invalid_18.tl` |
| Missing `RUN` | `tests/invalid_01.tl`, `tests/invalid_17.tl` |
| Duplicate task name | `tests/invalid_05.tl` |
| Duplicate `RUN` | `tests/invalid_13.tl` |
| Duplicate schedule | `tests/invalid_14.tl` |
| Duplicate condition | `tests/invalid_15.tl` |
| Undefined dependency | `tests/invalid_03.tl` |
| Undefined `BEFORE` target | `tests/invalid_11.tl` |
| Duplicate dependency | `tests/invalid_16.tl`, `tests/invalid_22.tl` |
| Circular dependency | `tests/invalid_04.tl`, `tests/invalid_10.tl` |
| Invalid time | `tests/invalid_07.tl` |
| Missing closing brace | `tests/invalid_06.tl` |
| Missing task name | `tests/invalid_02.tl` |
| Unquoted script | `tests/invalid_08.tl` |
| Unterminated string | `tests/invalid_09.tl` |
| Unknown token | `tests/invalid_21.tl` |
| Condition without dependency | `tests/invalid_19.tl` |
| Bad `WHEN` syntax | `tests/invalid_20.tl` |
| Empty `RUN` command | `tests/invalid_23.tl`, `tests/invalid_24.tl` |
| Overlong identifier | `tests/invalid_25.tl` |

Current suite size: 40 tests, with 15 valid programs and 25 invalid programs.

## Semantic Validation Explanation

The grammar checks whether the input has the right shape. Semantic validation checks whether the workflow makes sense after parsing.

TaskLang++ validates:

- missing `RUN`
- duplicate task names
- duplicate `RUN` statements
- duplicate schedules
- duplicate conditions
- undefined dependencies
- duplicate dependencies
- undefined `BEFORE` targets
- circular dependencies
- conditions without dependencies
- maximum task and dependency limits
- maximum identifier and string lengths

`BEFORE` is resolved after all tasks are parsed. If task `compileAssets` says `BEFORE packageApp`, then `packageApp` is updated to depend on `compileAssets`.

Circular dependencies are found with depth-first search over the dependency graph. The error explains that the workflow cannot execute and prints the dependency chain.

## Sample Valid Programs

Simple daily task:

```tl
TASK dailyReport {
    RUN "report.py"
    EVERY DAY AT 06:00
}
```

Daily task without a fixed time:

```tl
TASK dailyNoTime {
    RUN "daily.sh"
    EVERY DAY
}
```

Event-based task:

```tl
TASK deployOnPush {
    RUN "deploy.sh"
    WHEN push
}
```

Workflow with dependency and condition:

```tl
TASK backupDB {
    RUN "backup.sh"
    EVERY DAY AT 02:00
}

TASK sendReport {
    RUN "report.py"
    DEPENDS ON backupDB
    IF success
}
```

## Sample Invalid Programs

Missing `RUN`:

```tl
TASK noRun {
    EVERY DAY AT 06:00
}
```

Duplicate schedule:

```tl
TASK duplicateSchedule {
    RUN "script.sh"
    AT 08:00
    EVERY DAY AT 09:00
}
```

Circular dependency:

```tl
TASK taskA {
    RUN "a.sh"
    AFTER taskB
}

TASK taskB {
    RUN "b.sh"
    AFTER taskA
}
```

## Sample Output

```text
Parsing TaskLang++ input...

--- EXECUTION START ---

Executing Task: backupDB
  Script: "backup.sh"
  Schedule: EVERY DAY AT 02:00
  Depends on: (none)
  Condition: (none)

Executing Task: sendReport
  Script: "report.py"
  Schedule: (none)
  Depends on: backupDB
  Condition: success

--- EXECUTION COMPLETE ---
```

## Known Limitations

- Scripts are simulated and printed; they are not executed.
- Conditions are limited to `success` and `failure`.
- There are no retries, timeouts, monthly schedules, or date ranges.
- String literals do not support escaped quotes.
- The scheduler does not calculate real calendar times.
- The implementation uses fixed-size arrays to keep the project simple.

## Future Improvements

Possible future features:

- `RETRY n` for retry attempts
- `TIMEOUT HH:MM` or timeout seconds
- monthly schedules
- date ranges
- named environments
- richer conditions such as `IF backupDB.success`
- real sandboxed script execution
- export to cron-like formats

## Submission Notes

Do not submit generated build artifacts such as `tasklang`, `lex.yy.c`, `parser.tab.c`, `parser.tab.h`, `parser.output`, object files, `.DS_Store`, `__MACOSX`, or `*.dSYM` directories. Run `make clean` before packaging the source code.
