#!/usr/bin/env zsh

# The tests avoid using wd's internal functions to check the state of
# warp points. We use `--quiet` to prevent the test output being
# flooded by wd's output.


### Variables

# use a test config file, which is removed at the final test teardown.
export WD_CONFIG="$(mktemp)"

# used when testing
WD_TEST_DIR=test_dir
WD_TEST_DIR_2=test_dir_2
WD_TEST_WP=test
WD_TEST_WP_2=test2

### shUnit setup

# ZSH specific shUnit stuff
setopt shwordsplit
SHUNIT_PARENT=$0

oneTimeSetUp()
{
    WD_MOVE_TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/wd-move.XXXXXXXXXX") || exit 1
    WD_MOVE_TEST_DIR=${WD_MOVE_TEST_DIR:P}
}

# reset config for each test
setUp()
{
    cat /dev/null > "$WD_CONFIG"
}

oneTimeTearDown()
{
    command rm -rf "$WD_TEST_DIR" "$WD_TEST_DIR_2"
    command rm -rf -- "$WD_MOVE_TEST_DIR"
    command rm "$WD_CONFIG"
}

### Helpers

WD_PATH=${PWD}/..

wd()
{
    source "${WD_PATH}"/wd.sh "$@"
}

# MacOS's `wc` command adds extra padding to the front of the command.
# This removes any excess spaces.
wcl()
{
  wc -l | sed 's/^ *//'
}

total_wps()
{
    # total wps is the number of (non-empty) lines in the config
    echo "$(sed '/^\s*$/d' "$WD_CONFIG" | wcl)"
}

wp_exists()
{
    wd list | command grep -q "$1[[:space:]]*->"
    echo $?
}

create_test_wp()
{
    # create test dir
    mkdir "$WD_TEST_DIR"

    # create test wp
    cd "$WD_TEST_DIR"
    wd -q add "$WD_TEST_WP"
    cd ..
}

destroy_test_wp()
{
    command rm -rf "$WD_TEST_DIR"
    wd -q rm "$WD_TEST_DIR"
}


### Tests

# basic functionality
test_empty_config()
{
    assertEquals "should initially be an empty config" \
        0 "$(total_wps)"
}

test_wd_point()
{
    cwd="$PWD"
    wd -q add cwd
    assertTrue "should add the working directory as a custom warp point" \
        "$pipestatus"
    command rm -rf "$WD_TEST_DIR"
    command mkdir "$WD_TEST_DIR"
    cd "$WD_TEST_DIR"
    wd -q add
    assertTrue "should add another directory using a default warp point" \
        "$pipestatus"
    command mkdir "$WD_TEST_DIR_2"
    cd ..
    wd "$WD_TEST_DIR"
    assertTrue "should successfully warp to a default point" \
        "$pipestatus"
    assertEquals "should be in the default warped directory" \
        "$cwd/$WD_TEST_DIR" "$(pwd)"
    wd cwd
    assertEquals "should successfully return to cwd with a warp point" \
        "$cwd" "$(pwd)"
    wd "$WD_TEST_DIR" "$WD_TEST_DIR_2"
    assertTrue "should successfully warp to nested directory of point" \
        "$pipestatus"
    assertEquals "should be in the nested directory of the warp point" \
        "$cwd/$WD_TEST_DIR/$WD_TEST_DIR_2" "$(pwd)"
    wd -q moon
    assertFalse "should fail to warp to a point that does not exist" \
        "$pipestatus"
    wd -q "$WD_TEST_DIR" pluto 2&> /dev/null
    assertFalse "should fail warping to nonexistent nested directories" \
        "$pipestatus"
    command rm -rf "$WD_TEST_DIR"
}

test_simple_add_remove()
{
    wd -q add foo
    assertTrue "should successfully add wp 'foo'" \
        "$pipestatus"

    assertEquals "should have 1 wps" \
        1 "$(total_wps)"

    assertTrue "wp 'foo' should exist" \
        "$(wp_exists "foo")"

    wd -q rm foo
    assertEquals "wps should be empty" \
        0 "$(total_wps)"
}

test_default_add_remove()
{
    cwd=$(basename "$PWD")

    wd -q add
    assertTrue "should successfully add wp to PWD" \
               "$pipestatus"

    assertEquals "should have 1 wps" \
                 1 "$(total_wps)"

    assertTrue "wp to PWD should exist" \
               "$(wp_exists "$cwd")"

    wd -q rm
    assertEquals "wps should be empty" \
                 0 "$(total_wps)"
}

test_no_duplicates()
{
    wd -q add foo
    assertTrue "should successfully add 'foo'" \
        "$pipestatus"

    wd -q add foo
    assertFalse "should fail when adding duplicate of 'foo'" \
        "$pipestatus"
}

test_default_no_duplicates()
{
    cwd=$(basename "$PWD")

    wd -q add
    assertTrue "should successfully add warp point to PWD" \
               "$pipestatus"

    wd -q add
    assertFalse "should fail when adding duplicate of PWD" \
                "$pipestatus"

    wd -q -f add
    assertTrue "should successfully force-add warp point to PWD" \
               "$pipestatus"
}

test_default_multiple_directories()
{
    command rm -rf "$WD_TEST_DIR"
    command mkdir "$WD_TEST_DIR"
    cd "$WD_TEST_DIR"
    wd -q add
    assertTrue "should successfully add warp point to PWD" \
               "$pipestatus"
    cd ..
    command rmdir "$WD_TEST_DIR"

    command rm -rf "$WD_TEST_DIR_2"
    command mkdir "$WD_TEST_DIR_2"
    cd "$WD_TEST_DIR_2"
    wd -q add
    assertTrue "should successfully add warp point to another PWD" \
               "$pipestatus"
    cd ..
    command rmdir "$WD_TEST_DIR_2"
}

test_valid_identifiers()
{
    wd -q add .
    assertFalse "should not allow only dots" \
        "$pipestatus"

    wd -q add ..
    assertFalse "should not allow only dots" \
        "$pipestatus"

    wd -q add hej.
    assertTrue "should allow dots in name" \
        "$pipestatus"

    wd -q add "foo bar"
    assertFalse "should not allow whitespace" \
        "$pipestatus"

    wd -q add "foo:bar"
    assertFalse "should not allow colons" \
        "$pipestatus"

    wd -q add ":foo"
    assertFalse "should not allow colons" \
        "$pipestatus"

    wd -q add "foo:"
    assertFalse "should not allow colons" \
        "$pipestatus"

    wd -q add "foo/bar"
    assertFalse "should not allow slashes" \
        "$pipestatus"

    wd -q add "foo/"
    assertFalse "should not allow slashes" \
        "$pipestatus"

    wd -q add "/foo"
    assertFalse "should not allow slashes" \
        "$pipestatus"

    wd -q add "add"
    assertFalse "should not allow command names" \
        "$pipestatus"

    wd -q add "rm"
    assertFalse "should not allow command names" \
        "$pipestatus"

    wd -q add "mv"
    assertFalse "should not allow mv as a warp point name" \
        "$pipestatus"

    wd -q add "show"
    assertFalse "should not allow command names" \
        "$pipestatus"

    wd -q add "list"
    assertFalse "should not allow command names" \
        "$pipestatus"

    wd -q add "ls"
    assertFalse "should not allow command names" \
        "$pipestatus"

    wd -q add "path"
    assertFalse "should not allow command names" \
        "$pipestatus"

    wd -q add "clean"
    assertFalse "should not allow command names" \
        "$pipestatus"

    wd -q add "help"
    assertFalse "should not allow command names" \
        "$pipestatus"
}

test_wd_addcd()
{
    # Create a base directory for testing
    create_test_wp

    # Test with basic directory
    wd -q addcd "$WD_TEST_DIR"
    assertTrue "should successfully add default wp for directory" \
        "$(wp_exists "$(basename "$WD_TEST_DIR")")"

    # Test with a specific warp point name
    wd -q addcd "$WD_TEST_DIR" "$WD_TEST_WP_2"
    assertTrue "should successfully add specified wp for directory" \
        "$(wp_exists "$WD_TEST_WP_2")"

    # Test with force option
    wd -q addcd "$WD_TEST_DIR" -f
    assertTrue "should successfully force-add wp for directory" \
        "$(wp_exists "$(basename "$WD_TEST_DIR")")"

    # Test with a specific warp point name and force option
    wd -q addcd "$WD_TEST_DIR" "$WD_TEST_WP_2" -f
    assertTrue "should successfully force-add specified wp for directory" \
        "$(wp_exists "$WD_TEST_WP_2")"

    # Test with absolute path
    local abs_path="$PWD/$WD_TEST_DIR"
    wd -q addcd "$abs_path"
    assertTrue "should successfully add default wp for absolute directory path" \
        "$(wp_exists "$(basename "$abs_path")")"

    # Test with relative path including navigation
    mkdir -p "$WD_TEST_DIR/nested/extra"
    local rel_path="../$(basename "$PWD")/$WD_TEST_DIR"
    cd "$WD_TEST_DIR/nested/extra"
    wd -q addcd "$rel_path"
    assertTrue "should successfully add wp for relative path with navigation" \
        "$(wp_exists "$(basename "$rel_path")")"
    cd - > /dev/null

    # Test with nested directory paths
    local nested_path="$WD_TEST_DIR/nested/extra"
    wd -q addcd "$nested_path"
    assertTrue "should successfully add wp for nested directory path" \
        "$(wp_exists "$(basename "$nested_path")")"

    # Cleanup
    destroy_test_wp
}

test_wd_mv_renames_directory_and_updates_all_affected_points()
{
    local HOME="$WD_MOVE_TEST_DIR/rename"
    mkdir -p "$HOME/old [name]/nested" "$HOME/old [name]-other"
    touch "$HOME/old [name]/nested/file"
    wd -q addcd "$HOME/old [name]" main
    wd -q addcd "$HOME/old [name]" alternate
    wd -q addcd "$HOME/old [name]/nested" child
    wd -q addcd "$HOME/old [name]-other" other

    (cd "$HOME" && wd -q mv './old [name]/' 'new :: name')
    assertTrue "should rename the directory" "$?"
    assertFalse "should remove the old directory" '[[ -e "$HOME/old [name]" ]]'
    assertTrue "should move directory contents" '[[ -f "$HOME/new :: name/nested/file" ]]'
    assertEquals "$HOME/new :: name" "$(wd main && pwd -P)"
    assertEquals "$HOME/new :: name" "$(wd alternate && pwd -P)"
    assertEquals "$HOME/new :: name/nested" "$(wd child && pwd -P)"
    assertEquals "$HOME/old [name]-other" "$(wd other && pwd -P)"
    assertTrue "should save paths under HOME with a tilde" \
        'grep -Fxq "child:~/new :: name/nested" "$WD_CONFIG"'
}

test_wd_mv_into_existing_directory_uses_selected_config()
{
    local fixture="$WD_MOVE_TEST_DIR/into-existing"
    local selected_config="$fixture/linked-config"
    mkdir -p "$fixture/source" "$fixture/destination"
    touch "$fixture/config"
    ln -s config "$selected_config"
    wd -q --config "$selected_config" addcd "$fixture/source" selected
    wd -q addcd "$fixture/source" default
    local before=$(<"$WD_CONFIG")

    wd -q --config "$selected_config" mv "$fixture/source" "$fixture/destination/"
    assertTrue "should move the source into the destination" "$?"
    assertTrue '[[ -d "$fixture/destination/source" ]]'
    assertTrue "should preserve the config symlink" '[[ -L "$selected_config" ]]'
    assertEquals "$fixture/destination/source" "$(wd -c "$selected_config" selected && pwd -P)"
    assertEquals "should not change the default config" "$before" "$(<"$WD_CONFIG")"
}

test_wd_mv_leaves_config_unchanged_when_move_fails()
{
    local fixture="$WD_MOVE_TEST_DIR/failed"
    mkdir -p "$fixture/source/nested"
    touch "$fixture/file"
    wd -q addcd "$fixture/source" main
    wd -q addcd "$fixture/source/nested" child
    local before=$(<"$WD_CONFIG")

    wd -q mv "$fixture/source" "$fixture/file"
    assertFalse "should fail to move a directory over a file" "$?"
    assertTrue '[[ -d "$fixture/source/nested" ]]'
    assertTrue '[[ -f "$fixture/file" ]]'
    assertEquals "$before" "$(<"$WD_CONFIG")"
}

test_wd_mv_rejects_invalid_operands()
{
    local fixture="$WD_MOVE_TEST_DIR/invalid"
    mkdir -p "$fixture/source"
    touch "$fixture/file"
    ln -s source "$fixture/link"
    wd -q addcd "$fixture/source" main
    local before=$(<"$WD_CONFIG")

    wd -q mv "$fixture/source"
    assertFalse "should require a destination" "$?"
    wd -q mv "$fixture/source" "$fixture/destination" extra
    assertFalse "should reject extra operands" "$?"
    wd -q mv "$fixture/file" "$fixture/destination"
    assertFalse "should reject a file as the source" "$?"
    wd -q mv "$fixture/link//" "$fixture/destination"
    assertFalse "should reject a symlink as the source" "$?"
    assertTrue '[[ -d "$fixture/source" && ! -e "$fixture/destination" ]]'
    assertEquals "$before" "$(<"$WD_CONFIG")"
}

test_wd_mv_refuses_to_break_points_in_read_only_config()
{
    local fixture="$WD_MOVE_TEST_DIR/read-only"
    mkdir -p "$fixture/source"
    wd -q addcd "$fixture/source" main
    local before=$(<"$WD_CONFIG")
    chmod a-w "$WD_CONFIG"
    if [[ -w $WD_CONFIG ]]; then
        # Privileged users can still write to this file.
        chmod u+w "$WD_CONFIG"
        return
    fi

    wd -q mv "$fixture/source" "$fixture/destination"
    local move_status=$?
    chmod u+w "$WD_CONFIG"
    assertFalse "should fail before moving if a point cannot be updated" "$move_status"
    assertTrue '[[ -d "$fixture/source" && ! -e "$fixture/destination" ]]'
    assertEquals "$before" "$(<"$WD_CONFIG")"
}

test_wd_mv_without_matching_points_accepts_dash_prefixed_paths()
{
    local fixture="$WD_MOVE_TEST_DIR/untracked"
    mkdir -p "$fixture/-f" "$fixture/unrelated"
    wd -q addcd "$fixture/unrelated" other
    local before=$(<"$WD_CONFIG")

    (cd "$fixture" && wd -q mv -- -f -q)
    assertTrue "should move a directory without warp points" "$?"
    assertTrue '[[ -d "$fixture/-q" && ! -e "$fixture/-f" ]]'
    assertEquals "$before" "$(<"$WD_CONFIG")"
}


test_removal()
{
    wd -q add foo

    wd -q rm bar
    assertFalse "should fail when removing non-existing point" \
                "$pipestatus"

    wd -q rm foo
    assertTrue "should remove existing point" \
               "$pipestatus"
}

test_list()
{
    wd -q add foo

    # add one to expected number of lines, because of header msg
    assertEquals "should only be one warp point" \
        "$(wd list | wcl)" 2

    wd -q add bar

    assertEquals "should be more than one warp point" \
        "$(wd list | wcl)" 3

    mkdir test:dir
    cd test:dir
    wd -q add testdir
    cd ..
    rmdir test:dir

    assertEquals "should be three warp points" \
        "$(wd list | wcl)" 4

    wd list | grep -q "test:dir"
    assertTrue "should display the full colon-holding name" \
        "$?"

}

test_show()
{
    if [[ ! $(wd show) =~ "No warp point to $(echo "$PWD" | sed "s:$HOME:~:")" ]]
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

    # test target in $HOME is listed/shown
    cd ${HOME}
    wd -q add home
    if [[ ! $(wd show) =~ '1 warp point.*:.*home' ]]
    then
        fail "should show warp point 'home'"
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
    dir="$HOME/.wdunittest"

    # create test dir
    command mkdir "$dir"
    cd "$dir"

    # add warp point
    wd -q add test

    # remove test dir
    cd ..
    command rmdir "$dir"

    if [[ ! $(echo "n" | wd clean) =~ "Cleanup aborted" ]]
    then
        fail "should be able to abort cleanup"
    fi

    if [[ ! $(echo "y" | wd clean) =~ ".*1 warp point\(s\) removed" ]]
    then
        fail "should remove one warp point when answering yes"
    fi

    # recreate test dir
    command mkdir "$dir"
    cd "$dir"

    # add warp point
    wd -q add test

    if [[ ! $(echo "y" | wd clean) =~ "No warp points to clean, carry on!" ]]
    then
        fail "there should be no invalid warp point"
    fi

	wd -q -f add test

    # remove test dir
    cd ..
    command rmdir "$dir"

    if [[ ! $(wd clean -f) =~ ".*1 warp point\(s\) removed" ]]
    then
        fail "should remove one warp point when using force"
    fi
}

test_ls()
{
    # set up
    create_test_wp

    # create test files in dir
    touch "$WD_TEST_DIR/foo"
    touch "$WD_TEST_DIR/bar"

    # assert correct output
    if [[ ! $(wd ls $WD_TEST_WP) =~ "bar.*foo" ]]
    then
        fail "should list correct files"
    fi

    # clean up
    destroy_test_wp
}

test_path()
{
    # set up
    create_test_wp

    local pwd=$(echo "$PWD" | sed "s:~:${HOME}:g")

    # assert correct output
    if [[ ! $(wd path "$WD_TEST_WP") =~ "${pwd}/${WD_TEST_DIR}" ]]
    then
        fail "should give correct path"
    fi

    # clean up
    destroy_test_wp
}

test_config()
{
    local arg_config="$(mktemp)"
    local wd_config_lines=$(total_wps)

    wd -q --config "$arg_config" add

    # confirm $WD_CONFIG was unchanged
    assertEquals "$wd_config_lines" "$(total_wps)"
    assertEquals "$wd_config_lines" 0

    # confirm --config was changed
    assertEquals 1 "$(wcl < "$arg_config")"
    assertEquals 1 "$(WD_CONFIG=$arg_config total_wps)"

    command rm "$arg_config"
}


# Go go gadget
. ./shunit2/shunit2
