# Test 11: DEPENDS ON keyword sequence
TASK prepareData {
    RUN "prepare.py"
    EVERY DAY AT 05:30
}

TASK trainModel {
    RUN "train.py"
    DEPENDS ON prepareData
    IF success
}
