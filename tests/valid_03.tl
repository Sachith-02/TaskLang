# Test 03: Weekly schedule with different days
TASK weeklyDigest {
    RUN "digest_mailer.py"
    EVERY WEEK ON MONDAY AT 08:00
}

TASK archiveLogs {
    RUN "archive.sh"
    EVERY WEEK ON FRIDAY AT 23:30
}
