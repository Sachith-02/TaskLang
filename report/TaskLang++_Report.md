# TaskLang++ Report

## Title

TaskLang++: A Domain-Specific Language for Task Scheduling and Automation  
Module: SE2052 Programming Paradigms  
Assignment: Individual Take-Home Assignment  
Student Name: [Your Name]  
Student ID: [Your ID]  
Submission Date: [Submission Date]

## Introduction

TaskLang++ is a small domain-specific language for describing scheduled and
dependent automation tasks. A program defines named tasks, script commands,
time-based or event-based schedules, dependencies, and simple success or
failure conditions.

The implementation uses Flex for lexical analysis and Bison for parsing.
After parsing, semantic validation checks the complete workflow and the
interpreter prints a simulated execution order. It never executes real
operating-system commands.

## Domain and Scope

Automation workflows repeatedly answer three questions:

- What command should run?
- When should it run?
- Which tasks must finish first?

TaskLang++ expresses these ideas directly while remaining small enough for the
assignment. It supports:

- task definitions using `TASK name { ... }`
- one required `RUN "command"` per task
- `EVERY DAY`, daily-at-time, weekly, and one-time schedules
- event schedules using `WHEN eventName`
- `AFTER`, `BEFORE`, `DEPENDS`, and `DEPENDS ON`
- `IF success` and `IF failure`
- comments beginning with `#`

The language intentionally excludes real command execution, retries, timeouts,
monthly schedules, and general Boolean expressions.

## Syntax Design

The syntax uses a small set of readable scheduling keywords. For example:

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

This states the workflow more directly than a general-purpose program with
configuration objects and scheduling APIs.

## Main Grammar

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
              = "IF", ("success" | "failure") ;
```

The lexer recognizes identifiers, quoted strings, valid 24-hour times, invalid
time-like values, braces, keywords, comments, and whitespace. Keyword rules
appear before the identifier rule so reserved words cannot be used
accidentally as names.

## Parser and Semantic Validation

The parser builds a fixed-size in-memory task table. Fixed-size arrays keep the
implementation readable and avoid dependencies beyond Flex, Bison, a C
compiler, Make, and Python.

Checks that require knowledge of the complete program are performed after
parsing. These include:

- missing, empty, or duplicate `RUN` statements
- duplicate task names, schedules, and conditions
- undefined or duplicate dependencies
- undefined `BEFORE` targets
- conditions without a dependency
- circular dependencies
- maximum task, dependency, identifier, and string limits

`BEFORE` is resolved after every task is known. If task `A` declares
`BEFORE B`, task `B` is updated to depend on `A`.

Circular dependencies are detected with depth-first search. Each task is a
graph node and each dependency is an edge. Reaching a node that is already in
the current DFS stack proves that the workflow contains a cycle. A valid
workflow is printed in topological order so dependencies appear before their
dependent tasks.

## Error Handling

TaskLang++ prints separate lexical, syntax, and semantic error messages.
Focused recovery rules provide useful messages for malformed `RUN`, schedule,
dependency, and condition statements. Invalid input exits with code `1`;
valid input exits with code `0`.

The lexer accepts both Unix LF and Windows CRLF line endings. Overlong
identifiers and strings are rejected instead of being silently truncated.
Bison destructors release string values discarded during parser recovery.

## Testing

The automated suite contains:

- 15 valid programs
- 25 invalid programs
- 40 tests in total

Coverage includes every schedule form, every dependency spelling, both
conditions, comments, execution ordering, missing and duplicate statements,
undefined references, invalid times, malformed syntax, empty commands,
overlong identifiers, and circular graphs.

The full suite runs with:

```sh
make test
```

Individual cases can be selected:

```sh
make test valid_01
make test valid_01 valid_02 invalid_01
```

The test runner requires exact exit codes. Therefore a crash cannot be
mistaken for the expected rejection of an invalid program.

Verification also includes conflict-free Bison generation, compilation with
warnings treated as errors, AddressSanitizer and UndefinedBehaviorSanitizer
runs, CRLF input, and malformed-input stress tests.

## Reflection

The main design challenge was separating grammar rules from workflow rules.
The grammar can recognize `AFTER backupDB`, but only a later semantic pass can
confirm that `backupDB` exists. Duplicate names, reverse `BEFORE`
relationships, conditions, and cycles have the same whole-program
requirement.

The daily schedule forms share the prefix `EVERY DAY`. Precedence keeps
`EVERY DAY` and `EVERY DAY AT HH:MM` readable without introducing parser
conflicts. The Makefile treats shift/reduce and reduce/reduce conflicts as
build failures.

The graph representation made dependency validation and execution ordering
clear. DFS is suitable for cycle detection, while Kahn's algorithm provides a
simple topological execution order.

Fixed limits are a deliberate trade-off. They keep memory management and the
assignment implementation straightforward, while explicit limit checks avoid
silent data corruption.

## Limitations and Future Work

- Scripts are simulated and never executed.
- Strings do not support escaped quotes.
- Conditions are limited to `success` and `failure`.
- The scheduler does not calculate real calendar dates.
- Task and dependency counts use fixed limits.

Possible future extensions include retries, timeouts, monthly schedules,
richer task-specific conditions, and export to cron-like formats. These are
outside the current assignment scope.
