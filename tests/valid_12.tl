# Test 12: BEFORE creates a reverse dependency
TASK compileAssets {
    RUN "compile_assets.sh"
    BEFORE packageApp
}

TASK packageApp {
    RUN "package.sh"
}
