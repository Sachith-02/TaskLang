# AGENTS.md

## Project

This repository contains TaskLang++, a small DSL for task scheduling and automation. It is implemented using Flex and Bison for a second-year Programming Paradigms assignment.

Keep the project simple, readable, and assignment-focused. Do not turn it into a production scheduler.

## Important Files

- `lexer.l` - Flex lexer
- `parser.y` - Bison parser and semantic validation
- `Makefile` - build, test, demo, clean commands
- `run_tests.py` - automated test runner
- `tests/valid_*.tl` - valid TaskLang++ programs
- `tests/invalid_*.tl` - invalid TaskLang++ programs
- `README.md` - project documentation
- `report/TaskLang++_Report.md` - report draft

## Commands

Build:

```bash
make clean
make
```

Test:

```bash
make test
```

Optional Python test runner:

```bash
python3 run_tests.py
```

Demo:

```bash
make demo
```

Clean generated files:

```bash
make clean
```

## Submission Hygiene

Do not commit or submit generated build artifacts:

- `tasklang`
- `lex.yy.c`
- `parser.tab.c`
- `parser.tab.h`
- `parser.output`
- `*.o`
- `.DS_Store`
- `__MACOSX`
- `*.dSYM`

Run `make clean` before packaging the final source submission.

## Style Notes

- Keep keyword lexer rules before the identifier rule.
- Keep grammar changes small and conflict-free.
- Prefer clear semantic checks over complicated grammar rules.
- Do not add dependencies beyond Flex, Bison, gcc or clang, make, and python3.
- Preserve the readable TaskLang++ syntax used in the tests, README, and report.
