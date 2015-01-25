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

WD_PATH=${PWD}/..

wd()
{
    # run the local wd with the test config
    ${WD_PATH}/wd.sh -d -c $WD_TEST_CONFIG "$@"
}

total_wps()
{
    # total wps is the number of (non-empty) lines in the config
    echo $(cat $WD_TEST_CONFIG | sed '/^\s*$/d' | wc -l)
}

wp_exists()
{
    wd list | grep -q "$1[[:space:]]*->"
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


test_list()
{
    wd -q add foo

    # add one to expected number of lines, because of header msg
    assertEquals "should only be one warp point" \
        $(wd list | wc -l) 2

    wd -q add bar

    assertEquals "should be more than one warp point" \
        $(wd list | wc -l) 3
}

test_show()
{
    if [[ ! $(wd show) =~ "No warp point to $(echo $PWD | sed "s:$HOME:~:")" ]]
    then
        fail "should show no warp points"
    fi

    wd -q add foo

    if [[ ! $(wd show) =~ '1 warp point.*foo' ]]
    then
        fail "should show 1 warp point 'foo'"
    fi

    wd -q add bar

    if [[ ! $(wd show) =~ '2 warp point.*foo bar' ]]
    then
        fail "should show 2 warp points 'foo bar'"
    fi

    # test with optional name argument
    if [[ ! $(wd show foo) =~ 'Warp point:' ]]
    then
        fail "should show warp point 'foo'"
    fi

    if [[ ! $(wd show qux) =~ 'No warp point named' ]]
    then
        fail "should not show warp point 'qux'"
    fi
}

test_quiet()
{
    if [[ ! $(wd -q add foo) == "" ]]
    then
        fail "should suppress all output from add"
    fi

    if [[ ! $(wd -q show foo) == "" ]]
    then
        fail "should suppress all output from show"
    fi

    if [[ ! $(wd -q list) == "" ]]
    then
        fail "should suppress all output from ls"
    fi

    if [[ ! $(wd -q rm foo) == "" ]]
    then
        fail "should suppress all output from rm"
    fi
}

test_clean()
{
    dir=test_dir

    # create test dir
    mkdir $dir
    cd $dir

    # add warp point
    wd -q add test

    # remove test dir
    cd ..
    rmdir $dir

    if [[ ! $(echo "n" | wd clean) =~ "Cleanup aborted" ]]
    then
        fail "should be able to abort cleanup"
    fi

    if [[ ! $(echo "y" | wd clean) =~ ".*1 warp point\(s\) removed" ]]
    then
        fail "should remove one warp point when answering yes"
    fi

    # recreate the test dir
    dir=test_dir

    # create test dir
    mkdir $dir
    cd $dir

    # add warp point
    wd -q add test

    # remove test dir
    cd ..
    rmdir $dir

    if [[ ! $(wd clean!) =~ ".*1 warp point\(s\) removed" ]]
    then
        fail "should remove one warp point when using force"
    fi
}


# Go go gadget
. ./shunit2/shunit2
