# Test 10: Comments mixed throughout
TASK nightlyBackup {
    # This runs every day
    RUN "nightly.sh"
    EVERY DAY AT 03:00  # early morning
}

# The cleanup runs after backup
TASK cleanTmp {
    RUN "clean.sh"          # removes temp files
    AFTER nightlyBackup
    IF success
}
