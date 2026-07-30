#!/bin/bash

# prepare_submission.sh
# Creates a clean TaskLang++ submission package
# Usage: ./prepare_submission.sh

set -euo pipefail

REPORT="report/TaskLang++_Report.md"
REPORT_HAS_PLACEHOLDERS=0

if [ ! -f "$REPORT" ]; then
    echo "Error: required report is missing: $REPORT" >&2
    echo "Restore or create the report before preparing the submission." >&2
    exit 1
fi

if grep -Eq '\[(Your Name|Your ID|Submission Date)\]' "$REPORT"; then
    REPORT_HAS_PLACEHOLDERS=1
fi

for tool in make zip unzip; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: required command '$tool' was not found." >&2
        exit 1
    fi
done

echo "╔════════════════════════════════════════╗"
echo "║  TaskLang++ Submission Preparation     ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Step 1: Clean the project
echo "Step 1: Cleaning project..."
make clean
echo "  ✓ Project cleaned"
echo ""

# Step 2: Create submission directory
echo "Step 2: Setting up submission directory..."
if [ -d "SE2052_TaskLang_Submission" ]; then
    rm -rf SE2052_TaskLang_Submission
fi
mkdir -p SE2052_TaskLang_Submission
echo "  ✓ Directory created: SE2052_TaskLang_Submission/"
echo ""

# Step 3: Copy report
echo "Step 3: Copying report..."
cp "$REPORT" SE2052_TaskLang_Submission/
echo "  ✓ Report copied"
echo ""

# Step 4: Create source code ZIP
echo "Step 4: Creating source code archive..."

# Create tasklang_code.zip with only required files
zip -r SE2052_TaskLang_Submission/tasklang_code.zip \
  lexer.l \
  parser.y \
  Makefile \
  README.md \
  run_tests.py \
  AGENTS.md \
  tests/ \
  "$REPORT" \
  > /dev/null 2>&1

# Verify ZIP was created
if [ -f "SE2052_TaskLang_Submission/tasklang_code.zip" ]; then
    ZIP_SIZE=$(du -h SE2052_TaskLang_Submission/tasklang_code.zip | cut -f1)
    echo "  ✓ Archive created: tasklang_code.zip ($ZIP_SIZE)"
else
    echo "  ✗ Failed to create archive!"
    exit 1
fi

echo ""
echo "Step 5: Verifying submission structure..."
echo ""
echo "  Submission directory contents:"
ls -lh SE2052_TaskLang_Submission/ | awk 'NR>1 {printf "    %s  %s\n", $9, $5}'
echo ""

echo "Step 6: Verifying ZIP contents..."
echo ""
unzip -l SE2052_TaskLang_Submission/tasklang_code.zip | tail -5
echo ""

if [ "$REPORT_HAS_PLACEHOLDERS" -eq 1 ]; then
    echo "╔════════════════════════════════════════╗"
    echo "║  ⚠ Package Created - Review Required   ║"
    echo "╚════════════════════════════════════════╝"
else
    echo "╔════════════════════════════════════════╗"
    echo "║  ✓ Submission Ready for Upload         ║"
    echo "╚════════════════════════════════════════╝"
fi
echo ""
echo "Submission folder: SE2052_TaskLang_Submission/"
echo "  - TaskLang++_Report.md (report)"
echo "  - tasklang_code.zip (source code)"
echo ""
echo "Next steps:"
if [ "$REPORT_HAS_PLACEHOLDERS" -eq 1 ]; then
    echo "  1. Replace the bracketed student details in $REPORT"
    echo "  2. Run this script again"
    echo "  3. Upload SE2052_TaskLang_Submission/ to the assignment portal"
else
    echo "  1. Review the report and code"
    echo "  2. Upload SE2052_TaskLang_Submission/ to the assignment portal"
fi
echo ""
