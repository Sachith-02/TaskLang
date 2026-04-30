# Test 08: DEPENDS keyword (synonym for AFTER)
TASK sourceTask {
    RUN "source.sh"
    EVERY DAY AT 05:00
}

TASK derivedTask {
    RUN "derived.sh"
    DEPENDS sourceTask
}
