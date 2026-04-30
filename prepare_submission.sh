#!/bin/bash

# prepare_submission.sh
# Creates a clean TaskLang++ submission package
# Usage: ./prepare_submission.sh

set -e

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
cp report/TaskLang++_Report.md SE2052_TaskLang_Submission/
echo "  ✓ Report copied"
echo ""

# Step 4: Create source code ZIP
echo "Step 4: Creating source code archive..."
cd SE2052_TaskLang_Submission

# Create tasklang_code.zip with only required files
zip -r tasklang_code.zip \
  ../lexer.l \
  ../parser.y \
  ../Makefile \
  ../README.md \
  ../run_tests.py \
  ../AGENTS.md \
  ../tests/ \
  ../report/TaskLang++_Report.md \
  > /dev/null 2>&1

# Verify ZIP was created
if [ -f "tasklang_code.zip" ]; then
    ZIP_SIZE=$(du -h tasklang_code.zip | cut -f1)
    echo "  ✓ Archive created: tasklang_code.zip ($ZIP_SIZE)"
else
    echo "  ✗ Failed to create archive!"
    exit 1
fi

cd - > /dev/null

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

echo "╔════════════════════════════════════════╗"
echo "║  ✓ Submission Ready for Upload        ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Submission folder: SE2052_TaskLang_Submission/"
echo "  - TaskLang++_Report.md (report)"
echo "  - tasklang_code.zip (source code)"
echo ""
echo "Next steps:"
echo "  1. Review the report and code"
echo "  2. Upload SE2052_TaskLang_Submission/ to the assignment submission portal"
echo ""
