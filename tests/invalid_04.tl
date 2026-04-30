# Test I04: Circular dependency (A -> B -> A)
TASK taskA {
    RUN "a.sh"
    AFTER taskB
}

TASK taskB {
    RUN "b.sh"
    AFTER taskA
}
