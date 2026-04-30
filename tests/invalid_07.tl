# Test I07: Invalid time format (minutes > 59)
TASK badTime {
    RUN "script.sh"
    EVERY DAY AT 08:75
}
