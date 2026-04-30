# Test 06: AT-only schedule (no EVERY)
TASK midnightSnapshot {
    RUN "snapshot.py"
    AT 00:00
}
