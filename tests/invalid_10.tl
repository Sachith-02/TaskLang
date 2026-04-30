# Test I10: Three-way circular dependency
TASK alpha {
    RUN "alpha.sh"
    AFTER gamma
}

TASK beta {
    RUN "beta.sh"
    AFTER alpha
}

TASK gamma {
    RUN "gamma.sh"
    AFTER beta
}
