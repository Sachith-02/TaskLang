# Test I24: Empty RUN must still count when detecting duplicate RUN statements
TASK duplicateEmptyRun {
    RUN ""
    RUN "real.sh"
}
