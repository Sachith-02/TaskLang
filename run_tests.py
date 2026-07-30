#!/usr/bin/env python3
import glob
import os
import subprocess
import sys

if not os.path.isfile("./tasklang") or not os.access("./tasklang", os.X_OK):
    print("Error: ./tasklang is missing. Build it first with: make",
          file=sys.stderr)
    sys.exit(2)

all_tests = [(fname, True) for fname in sorted(glob.glob("tests/valid_*.tl"))]
all_tests += [(fname, False) for fname in sorted(glob.glob("tests/invalid_*.tl"))]

if len(sys.argv) > 1:
    tests_by_name = {
        os.path.splitext(os.path.basename(fname))[0]: (fname, should_pass)
        for fname, should_pass in all_tests
    }
    tests = []
    for requested_name in sys.argv[1:]:
        name = os.path.splitext(os.path.basename(requested_name))[0]
        if name not in tests_by_name:
            print("Unknown test case: " + requested_name, file=sys.stderr)
            sys.exit(2)
        tests.append(tests_by_name[name])
else:
    tests = all_tests

passed = 0
failed = 0
for fname, should_pass in tests:
    with open(fname, "rb") as f:
        r = subprocess.run(["./tasklang"], stdin=f, capture_output=True)
    expected_code = 0 if should_pass else 1
    ok = r.returncode == expected_code
    status = "PASS" if ok else "FAIL"
    label = "expected valid" if should_pass else "expected invalid"
    print(status + ": " + fname + " [" + label + "]")
    if ok:
        passed += 1
    else:
        failed += 1
        print("  expected exit code: " + str(expected_code))
        print("  actual exit code: " + str(r.returncode))
        if r.stdout:
            print("  stdout: " + r.stdout.decode(errors="replace").strip())
        print("  stderr: " + r.stderr.decode().strip())
print("")
print("Results: " + str(passed) + "/" + str(len(tests)) + " passed, " + str(failed) + " failed")

sys.exit(1 if failed else 0)
