# TaskLang++ Report

## Title

TaskLang++: A Domain-Specific Language for Task Scheduling and Automation  
Module: SE2052 Programming Paradigms  
Assignment: Individual Take-Home Assignment  
Student Name: [Your Name]  
Student ID: [Your ID]  
Submission Date: [Submission Date]

## Introduction

TaskLang++ is a small domain-specific language designed for task scheduling and automation workflows. It allows users to define named tasks, attach script commands, specify schedules, describe dependencies, and add simple success or failure conditions.

The implementation uses Flex for lexical analysis and Bison for parsing. After parsing, the program performs semantic validation and then simulates an execution order. The system does not execute real scripts; it prints the validated workflow in the order tasks would run.

## Domain Understanding

Many software projects require recurring or dependent automation. Examples include backups, report generation, deployments, cleanup jobs, and notifications. These workflows usually answer three questions:

- What script should run?
- When should it run?
- What must happen before it can run?

A general-purpose programming language can express these ideas, but it usually requires extra boilerplate. A focused DSL makes the workflow easier to read and easier to validate.

## DSL Scope

TaskLang++ supports:

- task definitions using `TASK name { ... }`
- script commands using `RUN "script"`
- time-based schedules:
  - `EVERY DAY`
  - `EVERY DAY AT HH:MM`
  - `EVERY WEEK ON <DAY> AT HH:MM`
  - `AT HH:MM`
- event-based schedules using `WHEN eventName`
- dependencies using `AFTER`, `BEFORE`, `DEPENDS`, and `DEPENDS ON`
- optional conditions using `IF success` and `IF failure`
- comments beginning with `#`

The project intentionally does not include real command execution, monthly schedules, retries, timeouts, or complex Boolean expressions. This keeps the grammar manageable and appropriate for the assignment.

## DSL Design Justification

The syntax was designed to be readable and close to natural scheduling language. For example:

```tl
TASK sendReport {
    RUN "report.py"
    AFTER backupDB
    IF success
}
```

This is easier to understand than a general-purpose implementation with functions, objects, or configuration files. The language separates task identity, script command, schedule, dependency, and condition into clear statements.

The design also keeps the grammar small. Schedules are limited to daily, weekly, one-time, and event-based forms. Conditions are limited to `success` and `failure`, which is enough to model common automation decisions without turning the language into a full programming language.

## Token Table

| Token | Lexeme or Pattern | Description |
| --- | --- | --- |
| `TASK` | `TASK` | Begins a task definition. |
| `RUN` | `RUN` | Specifies the script command. |
| `EVERY` | `EVERY` | Starts recurring schedule syntax. |
| `DAY` | `DAY` | Daily schedule keyword. |
| `WEEK` | `WEEK` | Weekly schedule keyword. |
| `ON` | `ON` | Used in weekly schedules and `DEPENDS ON`. |
| `AT` | `AT` | Introduces a time value. |
| `WHEN` | `WHEN` | Introduces an event-based schedule. |
| `AFTER` | `AFTER` | Current task depends on another task. |
| `BEFORE` | `BEFORE` | Another task depends on the current task. |
| `DEPENDS` | `DEPENDS` | Dependency keyword. |
| `IF` | `IF` | Starts a condition. |
| `SUCCESS` | `success` | Success condition. |
| `FAILURE` | `failure` | Failure condition. |
| `MONDAY` to `SUNDAY` | day names | Weekly schedule days. |
| `LBRACE` | `{` | Opens a task block. |
| `RBRACE` | `}` | Closes a task block. |
| `TIME_VAL` | `HH:MM` from `00:00` to `23:59` | Valid 24-hour time. |
| `INVALID_TIME` | invalid time-like pattern | Used for clearer invalid-time errors. |
| `STRING_LIT` | quoted string | Script name or command. |
| `IDENTIFIER` | letter or underscore followed by letters, digits, or underscores | Task names and event names. |

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

The parser includes a special empty-input rule so it can print a clear error message, but the DSL treats empty input as invalid.

## Lexer Implementation Explanation

The lexer is implemented in `lexer.l`. It recognizes:

- comments beginning with `#`
- keywords such as `TASK`, `RUN`, `EVERY`, `WHEN`, and `DEPENDS`
- day names for weekly schedules
- valid 24-hour times from `00:00` to `23:59`
- invalid time-like values for clearer error messages
- quoted strings for script names
- identifiers for task names and event names
- braces and whitespace
- lexical errors such as unknown characters and unterminated strings

Keyword rules are placed before the identifier rule. This is important because a word such as `TASK` should be recognized as a reserved keyword, not as an ordinary task name.

## Parser Implementation Explanation

The parser is implemented in `parser.y` using Bison. Its grammar follows the main language constructs:

- a program is a list of task definitions
- a task contains zero or more statements
- statements can be `RUN`, schedule, dependency, or condition statements
- schedules include daily, weekly, one-time, and event-based forms
- dependencies include both direct and reverse relationship syntax

Bison is configured so shift/reduce and reduce/reduce conflicts are treated as build errors. This protects the grammar from hidden ambiguity. The `EVERY DAY` and `EVERY DAY AT HH:MM` alternatives are handled carefully so both forms remain valid.

## Semantic Validation

Syntax validation checks whether the text matches the grammar. Semantic validation checks whether the parsed workflow makes sense. This separation is important because some rules require knowledge of the whole program.

Semantic checks include:

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

`BEFORE` relationship handling is a semantic step. If task `A` says `BEFORE B`, then task `B` is updated to depend on `A`. This cannot be fully resolved while reading one statement, because the target task might appear later in the file.

Circular dependency detection is implemented using depth-first search. Each task is treated as a node in a directed graph. If a task is reached again while it is already in the current DFS stack, the dependency graph contains a cycle. The error message prints the dependency chain and explains that the workflow cannot execute.

## Sample Valid Programs

Simple daily task:

```tl
TASK dailyReport {
    RUN "report.py"
    EVERY DAY AT 06:00
}
```

Daily task without time:

```tl
TASK dailyNoTime {
    RUN "daily.sh"
    EVERY DAY
}
```

Event-based schedule:

```tl
TASK deployOnPush {
    RUN "deploy.sh"
    WHEN push
}
```

Dependency and condition:

```tl
TASK backupDB {
    RUN "backup.sh"
    EVERY DAY AT 02:00
}

TASK sendReport {
    RUN "report.py"
    AFTER backupDB
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

Invalid time:

```tl
TASK badTime {
    RUN "script.sh"
    EVERY DAY AT 08:75
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

Condition without dependency:

```tl
TASK lonelyCondition {
    RUN "notify.sh"
    IF success
}
```

## Testing Results

The project includes automated tests in the `tests/` directory:

- 15 valid programs
- 22 invalid programs
- 37 total tests

The test suite covers:

- simple daily schedules
- `EVERY DAY` without a time
- weekly schedules
- one-time `AT` schedules
- event-based `WHEN` schedules
- `AFTER`, `BEFORE`, `DEPENDS`, and `DEPENDS ON`
- success and failure conditions
- multiple dependencies
- dependency chains
- comments and whitespace
- missing `RUN`
- duplicate names and duplicate statements
- undefined dependencies
- circular dependencies
- invalid times
- malformed syntax
- lexical errors

Expected result:

```text
Results: 37 passed, 0 failed
```

## Reflection

The main grammar design challenge was keeping the language expressive without making the parser unnecessarily complex. Scheduling languages can grow quickly if monthly schedules, date ranges, retries, and complex conditions are added. For this assignment, I limited the language to a small set of useful constructs so the grammar stayed understandable.

Parser conflict avoidance was an important part of the implementation. The `EVERY DAY` form and the `EVERY DAY AT HH:MM` form begin with the same tokens, so the grammar must make it clear how to parse both. Bison conflict warnings are treated as errors in the Makefile, which helped keep the parser clean.

Semantic validation is separate from syntax validation because many workflow errors cannot be detected by grammar alone. For example, the grammar can parse `AFTER backupDB`, but it cannot know whether `backupDB` is actually defined until the whole program has been read. The same is true for duplicate task names, circular dependencies, and conditions without dependencies.

Circular dependency detection required thinking about the workflow as a graph. A cycle means there is no valid execution order, because each task in the cycle waits for another task in the same cycle. The DFS implementation reports a readable chain so the user can understand and fix the workflow.

`BEFORE` relationship handling was another useful challenge. `AFTER B` means the current task depends on `B`, while `BEFORE B` means `B` depends on the current task. This reversed direction is easy for users to read, but it needs a separate semantic pass after all tasks are known.

The condition system is deliberately limited to `success` and `failure`. This is a trade-off. It makes the language less powerful than a full expression language, but it keeps the syntax simple and strongly connected to the assignment goal. More advanced conditions could be added later, but they would require more grammar rules and more semantic checks.

Overall, the project shows that parsing is only one part of language implementation. A useful DSL also needs clear design boundaries, helpful error messages, semantic validation, and good tests.

## Future Improvements

Possible future features include:

- retries, such as `RETRY 3`
- timeout values for long-running tasks
- monthly schedules
- date ranges
- named calendars
- environment variables for scripts
- richer conditions based on task names and exit codes
- real sandboxed execution of scripts
- exporting workflows to cron-like formats
