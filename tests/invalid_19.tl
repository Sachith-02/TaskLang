# Test I19: Condition without dependency
TASK lonelyCondition {
    RUN "notify.sh"
    IF success
}
