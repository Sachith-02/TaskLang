# Test 14: Event-based schedule
TASK deployOnPush {
    RUN "deploy.sh"
    WHEN push
}
