TASK base {
    RUN "base.sh"
}

TASK repeatedDependency {
    RUN "script.sh"
    AFTER base
    DEPENDS ON base
}
