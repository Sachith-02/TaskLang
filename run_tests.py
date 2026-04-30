#!/usr/bin/env python3
import glob
import subprocess
import sys

tests = [(fname, True) for fname in sorted(glob.glob("tests/valid_*.tl"))]
tests += [(fname, False) for fname in sorted(glob.glob("tests/invalid_*.tl"))]

passed = 0
failed = 0
for fname, should_pass in tests:
    with open(fname) as f:
        r = subprocess.run(["./tasklang"], stdin=f, capture_output=True)
    ok = (r.returncode == 0) == should_pass
    status = "PASS" if ok else "FAIL"
    label = "valid" if should_pass else "invalid (correctly rejected)"
    print(status + ": " + fname + " [" + label + "]")
    if ok:
        passed += 1
    else:
        failed += 1
        print("  stderr: " + r.stderr.decode().strip())
print("")
print("Results: " + str(passed) + "/" + str(len(tests)) + " passed, " + str(failed) + " failed")

sys.exit(1 if failed else 0)
