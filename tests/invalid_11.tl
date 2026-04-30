# Test I11: BEFORE references an undefined task
TASK firstStep {
    RUN "first.sh"
    BEFORE missingStep
}
