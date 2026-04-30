# Test I08: RUN with unquoted script name
TASK noQuotes {
    RUN script.sh
    EVERY DAY AT 08:00
}
