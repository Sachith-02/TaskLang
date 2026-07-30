# TaskLang++ build
#
# macOS ships an old Bison (2.3), but this grammar requires Bison 3.
# Prefer Homebrew Bison when it is installed; command-line overrides such as
# `make BISON=/path/to/bison` still take precedence.

TARGET := tasklang

CC ?= cc
FLEX ?= flex

BREW_BISON := $(firstword \
	$(wildcard /opt/homebrew/opt/bison/bin/bison) \
	$(wildcard /usr/local/opt/bison/bin/bison))
BISON ?= $(if $(BREW_BISON),$(BREW_BISON),bison)

CFLAGS ?= -Wall -Wextra -g
CPPFLAGS ?=
LDFLAGS ?=
LDLIBS ?=

BISONFLAGS ?= -d -v -Wconflicts-sr -Wconflicts-rr \
	-Werror=conflicts-sr -Werror=conflicts-rr
FLEXFLAGS ?=
FLEX_CFLAGS ?= -Wno-sign-compare

BISON_C := parser.tab.c
BISON_H := parser.tab.h
BISON_REPORT := parser.output
FLEX_C := lex.yy.c
OBJECTS := parser.tab.o lex.yy.o
GENERATED := $(BISON_C) $(BISON_H) $(BISON_REPORT) $(FLEX_C)

RUN_FILE ?= tests/valid_01.tl
TEST_FILES := $(sort $(wildcard tests/valid_*.tl tests/invalid_*.tl))
TEST_CASES := $(basename $(notdir $(TEST_FILES)))
REQUESTED_CASES := $(filter $(TEST_CASES),$(MAKECMDGOALS))

.DEFAULT_GOAL := all
.DELETE_ON_ERROR:

.PHONY: all build help check-tools run demo test test-verbose clean \
	$(TEST_CASES)

all: $(TARGET)

build: all

help:
	@echo "TaskLang++ Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make                  Build the TaskLang++ interpreter"
	@echo "  make run              Run tests/valid_01.tl"
	@echo "  make run RUN_FILE=FILE"
	@echo "                        Run a specific TaskLang++ source file"
	@echo "  make demo             Run three example programs"
	@echo "  make test             Run the complete test suite"
	@echo "  make test valid_01    Run one test case"
	@echo "  make test valid_01 valid_02"
	@echo "                        Run multiple test cases"
	@echo "  make test-verbose     Run every test and show its output"
	@echo "  make check-tools      Show the selected build tools"
	@echo "  make clean            Remove generated files"

check-tools:
	@command -v "$(CC)" >/dev/null 2>&1 || { \
		echo "Error: C compiler '$(CC)' was not found."; exit 1; \
	}
	@command -v "$(FLEX)" >/dev/null 2>&1 || { \
		echo "Error: Flex '$(FLEX)' was not found."; exit 1; \
	}
	@command -v "$(BISON)" >/dev/null 2>&1 || { \
		echo "Error: Bison 3 was not found."; \
		echo "On macOS, install it with: brew install bison"; exit 1; \
	}
	@echo "C compiler: $$($(CC) --version 2>/dev/null | head -n 1)"
	@echo "Flex:       $$($(FLEX) --version 2>/dev/null | head -n 1)"
	@echo "Bison:      $$($(BISON) --version 2>/dev/null | head -n 1)"
	@echo "Bison path: $(BISON)"

$(BISON_C): parser.y
	@$(BISON) --help 2>/dev/null | grep -q -- "--warnings" || { \
		echo "Error: TaskLang++ requires Bison 3 or newer."; \
		echo "Selected Bison: $(BISON)"; \
		echo "On macOS, install it with: brew install bison"; exit 1; \
	}
	$(BISON) $(BISONFLAGS) parser.y

# Bison creates the header together with parser.tab.c.
$(BISON_H): $(BISON_C)
	@test -f $@

$(FLEX_C): lexer.l $(BISON_H)
	$(FLEX) $(FLEXFLAGS) lexer.l

parser.tab.o: $(BISON_C) $(BISON_H)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $(BISON_C) -o $@

lex.yy.o: $(FLEX_C) $(BISON_H)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(FLEX_CFLAGS) -c $(FLEX_C) -o $@

$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $(OBJECTS) $(LDLIBS)

run: $(TARGET)
	@test -f "$(RUN_FILE)" || { \
		echo "Error: input file '$(RUN_FILE)' does not exist."; exit 1; \
	}
	@echo "=== Running $(RUN_FILE) ==="
	@./$(TARGET) < "$(RUN_FILE)"

demo: $(TARGET)
	@echo "=== Demo: Simple Daily Task ==="
	@./$(TARGET) < tests/valid_01.tl
	@echo ""
	@echo "=== Demo: Workflow with Dependencies ==="
	@./$(TARGET) < tests/valid_02.tl
	@echo ""
	@echo "=== Demo: Event-Based Schedule ==="
	@./$(TARGET) < tests/valid_14.tl

test: $(TARGET)
	@python3 run_tests.py $(REQUESTED_CASES)

# These aliases allow commands such as `make test valid_01 invalid_01`.
$(TEST_CASES): test
	@:

test-verbose: $(TARGET)
	@for file in tests/valid_*.tl tests/invalid_*.tl; do \
		echo ""; \
		echo "══════════════════════════════════════════"; \
		echo "  FILE: $$file"; \
		echo "══════════════════════════════════════════"; \
		./$(TARGET) < "$$file"; \
		status=$$?; \
		echo "(exit code: $$status)"; \
	done

clean:
	$(RM) $(TARGET) $(GENERATED) *.o
	$(RM) -r $(TARGET).dSYM __pycache__
