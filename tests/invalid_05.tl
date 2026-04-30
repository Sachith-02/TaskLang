# Test I05: Duplicate task name
TASK backup {
    RUN "backup.sh"
    EVERY DAY AT 02:00
}

TASK backup {
    RUN "another_backup.sh"
    EVERY DAY AT 03:00
}
