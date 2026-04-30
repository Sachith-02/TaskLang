# Test 05: Task with failure condition
TASK criticalJob {
    RUN "critical.sh"
    EVERY DAY AT 00:00
}

TASK alertOnFailure {
    RUN "alert.py"
    AFTER criticalJob
    IF failure
}
