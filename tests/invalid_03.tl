# Test I03: Undefined dependency
TASK orphan {
    RUN "orphan.sh"
    AFTER nonExistentTask
}
