#! /bin/zsh

# The tests avoid using wd's internal functions to check the state of
# warp points. We use `--quiet` to prevent the test output being
# flooded by wd's output.

# use a test config file, which is removed at the final test teardown.
WD_TEST_CONFIG=~/.warprc_test

### shUnit setup

# ZSH specific shUnit stuff
setopt shwordsplit
SHUNIT_PARENT=$0

# reset config for each test
setUp() {
    cat /dev/null > $WD_TEST_CONFIG
}

oneTimeTearDown() {
    rm $WD_TEST_CONFIG
}

### Helpers

wd() {
    # run the local wd with the test config
    ../wd.sh -c $WD_TEST_CONFIG "$@"
}

total_wps() {
    # total wps is the number of (non-empty) lines in the config
    echo $(cat $WD_TEST_CONFIG | sed '/^\s*$/d' | wc -l)
}

wp_exists() {
    wd ls | grep -q "$1[[:space:]]*->"
    echo $?
}

wp_exists() {
    wd ls | grep -q "$1[[:space:]]*->"
    echo $?
}


### Tests

test_empty_config() {
    assertEquals "should initially be an empty config" \
        0 $(total_wps)
}

test_simple_add_remove() {
    wd -q add foo
    assertEquals "should have 1 wps" \
        1 $(total_wps)

    assertTrue "wp 'foo' should exist" \
        $(wp_exists "foo")

    wd -q rm foo
    assertEquals "wps should be empty" \
        0 $(total_wps)
}

# Go go gadget
. ./shunit2/shunit2
