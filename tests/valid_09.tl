# Test 09: Edge case — single character identifiers and extreme times
TASK x {
    RUN "x.sh"
    AT 23:59
}

TASK y {
    RUN "y.sh"
    EVERY DAY AT 00:00
}
