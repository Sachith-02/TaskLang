TASK duplicateCondition {
    RUN "script.sh"
    IF success
    IF failure
}
