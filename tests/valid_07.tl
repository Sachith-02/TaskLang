# Test 07: Multiple dependencies (diamond dependency graph)
TASK fetchData {
    RUN "fetch.py"
    EVERY DAY AT 04:00
}

TASK processA {
    RUN "process_a.py"
    AFTER fetchData
}

TASK processB {
    RUN "process_b.py"
    AFTER fetchData
}

TASK aggregate {
    RUN "aggregate.py"
    AFTER processA
    AFTER processB
}
