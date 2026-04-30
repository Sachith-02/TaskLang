# Test 04: Task with no schedule (dependency-only task)
TASK buildApp {
    RUN "build.sh"
    EVERY DAY AT 01:00
}

TASK deployApp {
    RUN "deploy.sh"
    AFTER buildApp
    IF success
}

TASK notifyTeam {
    RUN "notify.py"
    AFTER deployApp
    IF success
}
