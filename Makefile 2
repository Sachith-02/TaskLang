CC      = gcc
CFLAGS  = -Wall -Wextra -g
BISONFLAGS = -d -v -Wconflicts-sr -Wconflicts-rr -Werror=conflicts-sr -Werror=conflicts-rr
FLEX_PREFIX := $(shell brew --prefix flex 2>/dev/null)
FLEX_LIB    := $(if $(FLEX_PREFIX),$(FLEX_PREFIX)/lib/libfl.a,-lfl)
LDFLAGS     = $(FLEX_LIB)
TARGET  = tasklang

BISON_OUT = parser.tab.c parser.tab.h
FLEX_OUT  = lex.yy.c

.PHONY: all
all: $(TARGET)

parser.tab.c parser.tab.h: parser.y
	bison $(BISONFLAGS) parser.y

lex.yy.c: lexer.l parser.tab.h
	flex lexer.l

$(TARGET): parser.tab.c lex.yy.c
	$(CC) $(CFLAGS) -o $(TARGET) parser.tab.c lex.yy.c $(LDFLAGS)

.PHONY: run
run: $(TARGET)
	@echo "=== Running tests/valid_01.tl ==="
	@./$(TARGET) < tests/valid_01.tl

.PHONY: demo
demo: $(TARGET)
	@echo "=== Demo: Simple Daily Task ==="
	@./$(TARGET) < tests/valid_01.tl
	@echo ""
	@echo "=== Demo: Workflow with Dependencies ==="
	@./$(TARGET) < tests/valid_02.tl
	@echo ""
	@echo "=== Demo: Event-Based Schedule ==="
	@./$(TARGET) < tests/valid_14.tl

.PHONY: test
test: $(TARGET)
	@echo ""
	@echo "╔══════════════════════════════════════╗"
	@echo "║   TaskLang++ Test Suite              ║"
	@echo "╚══════════════════════════════════════╝"
	@echo ""
	@PASS=0; FAIL=0; \
	echo "── VALID PROGRAMS (expect exit 0) ──────────────────"; \
	for f in tests/valid_*.tl; do \
		./$(TARGET) < "$$f" > /dev/null 2>&1; \
		if [ $$? -eq 0 ]; then \
			echo "  [PASS]  $$f"; PASS=$$((PASS+1)); \
		else \
			echo "  [FAIL]  $$f  <-- should have passed"; FAIL=$$((FAIL+1)); \
		fi; \
	done; \
	echo ""; \
	echo "── INVALID PROGRAMS (expect exit 1) ────────────────"; \
	for f in tests/invalid_*.tl; do \
		./$(TARGET) < "$$f" > /dev/null 2>&1; \
		if [ $$? -ne 0 ]; then \
			echo "  [PASS]  $$f  (correctly rejected)"; PASS=$$((PASS+1)); \
		else \
			echo "  [FAIL]  $$f  <-- should have failed"; FAIL=$$((FAIL+1)); \
		fi; \
	done; \
	echo ""; \
	echo "────────────────────────────────────────────────────"; \
	echo "  Results: $$PASS passed, $$FAIL failed"; \
	echo ""; \
	[ $$FAIL -eq 0 ]

.PHONY: test-verbose
test-verbose: $(TARGET)
	@for f in tests/valid_*.tl tests/invalid_*.tl; do \
		echo ""; \
		echo "══════════════════════════════════════════"; \
		echo "  FILE: $$f"; \
		echo "══════════════════════════════════════════"; \
		./$(TARGET) < "$$f"; \
		echo "(exit code: $$?)"; \
	done

.PHONY: clean
clean:
	rm -f $(TARGET) $(BISON_OUT) $(FLEX_OUT) parser.output
	rm -rf $(TARGET).dSYM
