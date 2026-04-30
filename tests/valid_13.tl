TASK first {
    RUN "first.sh"
    BEFORE second
}

TASK second {
    RUN "second.sh"
    BEFORE third
}

TASK third {
    RUN "third.sh"
}
