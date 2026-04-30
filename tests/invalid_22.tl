# Test I22: Duplicate dependency through BEFORE and AFTER
TASK build {
    RUN "build.sh"
    BEFORE deploy
}

TASK deploy {
    RUN "deploy.sh"
    AFTER build
}
