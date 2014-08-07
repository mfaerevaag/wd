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
setUp()
{
    cat /dev/null > $WD_TEST_CONFIG
}

oneTimeTearDown()
{
    rm $WD_TEST_CONFIG
}

### Helpers

wd()
{
    # run the local wd with the test config
    ../wd.sh -c $WD_TEST_CONFIG "$@"
}

total_wps()
{
    # total wps is the number of (non-empty) lines in the config
    echo $(cat $WD_TEST_CONFIG | sed '/^\s*$/d' | wc -l)
}

wp_exists()
{
    wd ls | grep -q "$1[[:space:]]*->"
    echo $?
}


### Tests

# basic functionality
test_empty_config()
{
    assertEquals "should initially be an empty config" \
        0 $(total_wps)
}

test_simple_add_remove()
{
    wd -q add foo
    assertTrue "should successfully add wp 'foo'" \
        $pipestatus

    assertEquals "should have 1 wps" \
        1 $(total_wps)

    assertTrue "wp 'foo' should exist" \
        $(wp_exists "foo")

    wd -q rm foo
    assertEquals "wps should be empty" \
        0 $(total_wps)
}

test_no_duplicates()
{
    wd -q add foo
    assertTrue "should successfully add 'foo'" \
        $pipestatus

    wd -q add foo
    assertFalse "should fail when adding duplicate of 'foo'" \
        $pipestatus
}


test_valid_identifiers()
{
    wd -q add .
    assertFalse "should not allow only dots" \
        $pipestatus

    wd -q add ..
    assertFalse "should not allow only dots" \
        $pipestatus

    wd -q add hej.
    assertTrue "should allow dots in name" \
        $pipestatus

    wd -q add "foo bar"
    assertFalse "should not allow whitespace" \
        $pipestatus

    wd -q add "foo:bar"
    assertFalse "should not allow colons" \
        $pipestatus

    wd -q add ":foo"
    assertFalse "should not allow colons" \
        $pipestatus

    wd -q add
    assertFalse "should not allow empty name" \
        $pipestatus
}


test_removal()
{
    wd -q add foo

    wd -q rm bar
    assertFalse "should fail when removing non-existing point" \
        $pipestatus

    wd -q rm foo
    assertTrue "should remove existing point" \
        $pipestatus
}

# Go go gadget
. ./shunit2/shunit2
