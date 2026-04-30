# Test I12: DEPENDS ON without a target task name
TASK badDependsOn {
    RUN "script.sh"
    DEPENDS ON
}
