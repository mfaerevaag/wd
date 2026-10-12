#!/usr/bin/env zsh

# The tests avoid using wd's internal functions to check the state of
# warp points. We use `--quiet` to prevent the test output being
# flooded by wd's output.


### Variables

# use a test config file, which is removed at the final test teardown.
export WD_CONFIG="$(mktemp)"
WD_TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/wd-tests.XXXXXXXXXX")

# used when testing
WD_TEST_DIR=test_dir
WD_TEST_DIR_2=test_dir_2
WD_TEST_WP=test
WD_TEST_WP_2=test2

### shUnit setup

# ZSH specific shUnit stuff
setopt shwordsplit
SHUNIT_PARENT=$0

# reset config for each test
setUp()
{
    cat /dev/null > "$WD_CONFIG"
}

oneTimeTearDown()
{
    command rm -rf "$WD_TEST_DIR" "$WD_TEST_DIR_2"
    command rm "$WD_CONFIG"
    command rm -rf "$WD_TEST_ROOT"
}

### Helpers

WD_PATH=${PWD}/..

wd()
{
    source "${WD_PATH}"/wd.sh "$@"
}

# Capture completion descriptions or search roots without an interactive terminal.
# Keep the completion stubs scoped to a subshell.
wd_completion()
(
    local state=$1
    local -a words=(wd "$2" '')
    _arguments() { return 1; }
    _describe()
    {
        if [[ $3 == 'Warp points' ]]; then
            printf '%s\n' "${(@P)4}"
        fi
        return 0
    }
    _path_files()
    {
        local base=$2
        local -a roots
        # Resolve the three -W forms: a word list, an absolute path, or an array name.
        if [[ $base == \(*\) ]]; then
            roots=( ${=base[2,-2]} )
        elif [[ $base == /* ]]; then
            roots=( "$base" )
        else
            roots=( "${(@P)base}" )
        fi
        printf '%s\n' "${roots[@]}"
    }
    source "${WD_PATH}"/_wd.sh
)

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
    local show_pwd=$PWD
    if [[ $PWD == "$HOME" || $PWD == "$HOME/"* ]]; then
        show_pwd="~${PWD#"$HOME"}"
    fi
    if [[ $(wd show) != *"No warp point to $show_pwd" ]]
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

    # assert correct output
    assertEquals "should give correct path" \
        "$PWD/$WD_TEST_DIR" "$(wd path "$WD_TEST_WP")"

    # clean up
    destroy_test_wp
}

test_home_path_expansion()
{
    local HOME="$WD_TEST_ROOT/home"
    local -a stored expected
    stored=(
        '~'
        '~/Documents'
        '~/Library/Mobile Documents/com~apple~CloudDocs'
        '~/foo~bar~baz'
        "$WD_TEST_ROOT/outside/foo~bar~baz"
        '~username/path'
        '~username'
        '~/literal\n\t\\path::  '
        "$WD_TEST_ROOT"'/outside/literal\n\t\\path  '
    )
    expected=(
        "$HOME"
        "$HOME/Documents"
        "$HOME/Library/Mobile Documents/com~apple~CloudDocs"
        "$HOME/foo~bar~baz"
        "$WD_TEST_ROOT/outside/foo~bar~baz"
        '~username/path'
        '~username'
        "$HOME"'/literal\n\t\\path::  '
        "$WD_TEST_ROOT"'/outside/literal\n\t\\path  '
    )

    local i
    for (( i = 1; i <= ${#stored}; i++ )); do
        printf 'point:%s\n' "${stored[$i]}" > "$WD_CONFIG"
        assertEquals "should expand only a complete leading home component: ${stored[$i]}" \
            "${expected[$i]}" "$(wd path point)"
        assertEquals "completion should search one intact, correctly expanded directory: ${stored[$i]}" \
            "${expected[$i]}" "$(wd_completion second_arg point)"
    done
}

test_home_path_round_trip()
{
    local HOME="$WD_TEST_ROOT/home"
    local original_pwd=$PWD
    local REPLY='caller value'
    local -a directories abbreviated
    directories=(
        "$HOME"
        "$HOME/Documents"
        "$HOME/Library/Mobile Documents/com~apple~CloudDocs"
        "$HOME"'/literal[glob]*?~one~two\n\t\\path  '
        "${HOME}-backup"
        "$WD_TEST_ROOT/outside/foo~bar~baz"
        "$WD_TEST_ROOT/outside$HOME/foo"
        "$HOME/repeated$HOME/foo"
    )
    abbreviated=(
        '~'
        '~/Documents'
        '~/Library/Mobile Documents/com~apple~CloudDocs'
        '~/literal[glob]*?~one~two\n\t\\path  '
        "${HOME}-backup"
        "$WD_TEST_ROOT/outside/foo~bar~baz"
        "$WD_TEST_ROOT/outside$HOME/foo"
        "~/repeated$HOME/foo"
    )

    local i output
    for (( i = 1; i <= ${#directories}; i++ )); do
        command mkdir -p "${directories[$i]}"
        cd "${directories[$i]}" || return
        wd -q add "point_$i"
        assertEquals "should abbreviate only the leading home component" \
            "point_$i:${abbreviated[$i]}" "$(command grep -F "point_$i:" "$WD_CONFIG")"
        assertEquals "should round trip through add and path" \
            "${directories[$i]}" "$(wd path "point_$i")"

        output=$(wd show "point_$i")
        [[ $output == *" -> ${abbreviated[$i]}" ]]
        assertTrue "should show the stored path literally" "$?"

        output=$(wd show)
        [[ $output == *'1 warp point(s) to current directory:'*"point_$i"* ]]
        assertTrue "should find the current directory, including literal pattern characters" "$?"

        output=$(wd list)
        [[ $output == *"point_$i  ->  ${abbreviated[$i]}"* ]]
        assertTrue "should list the stored path literally" "$?"

        cd "$original_pwd" || return
        wd "point_$i"
        assertEquals "should navigate to the original path" "${directories[$i]}" "$PWD"
    done

    local sub='sub~dir\n\t  '
    command mkdir -p "$PWD/$sub"
    cd "$original_pwd" || return
    wd "point_${#directories}" "$sub"
    assertEquals "should preserve literal characters in a navigation subpath" \
        "${directories[-1]}/$sub" "$PWD"
    wd -q show
    assertEquals "add, navigation and show should preserve the caller's REPLY" \
        'caller value' "$REPLY"
    cd "$original_pwd" || return
}

test_home_with_pattern_characters()
{
    local HOME="$WD_TEST_ROOT/home [literal]*"
    local original_pwd=$PWD
    local target="$HOME/Documents"
    command mkdir -p "$target"
    cd "$target" || return

    wd -q add point
    assertEquals "should treat HOME literally when abbreviating" \
        'point:~/Documents' "$(< "$WD_CONFIG")"
    assertEquals "should treat HOME literally when expanding" \
        "$target" "$(wd path point)"
    assertEquals "completion should treat HOME literally when abbreviating" \
        'point:~/Documents' "$(wd_completion first_arg '')"
    assertEquals "completion should preserve spaces and pattern characters in HOME" \
        "$target" "$(wd_completion second_arg point)"
    local output=$(wd show)
    [[ $output == *'1 warp point(s) to current directory:'*'point'* ]]
    assertTrue "should find a path beneath a home with pattern characters" "$?"
    cd "$original_pwd" || return
}

test_list_and_browse_home_boundaries()
{
    local HOME="$WD_TEST_ROOT/home"
    local REPLY='caller value'
    local -a stored expected
    stored=(
        "$HOME"
        "$HOME/Library/Mobile Documents/com~apple~CloudDocs"
        "${HOME}-backup"
        "$WD_TEST_ROOT/outside$HOME/foo"
        "$HOME/repeated$HOME/foo"
        '~username/path'
        "$HOME"'/literal\n\t\\path::  '
    )
    expected=(
        '~'
        '~/Library/Mobile Documents/com~apple~CloudDocs'
        "${HOME}-backup"
        "$WD_TEST_ROOT/outside$HOME/foo"
        "~/repeated$HOME/foo"
        '~username/path'
        '~/literal\n\t\\path::  '
    )
    local i
    for (( i = 1; i <= ${#stored}; i++ )); do
        printf 'point_%s:%s\n' "$i" "${stored[$i]}" >> "$WD_CONFIG"
    done
    # A manually edited config may end without a newline.
    printf 'last:%s' "$HOME/Documents" >> "$WD_CONFIG"

    # Capture fzf's input without requiring an interactive terminal.
    fzf() { command cat > "$WD_TEST_ROOT/browse-entries"; }
    wd browse
    unfunction fzf
    wd -q list
    assertEquals "browse and list should preserve the caller's REPLY" \
        'caller value' "$REPLY"

    local listed=$(wd list)
    local browsed=$(< "$WD_TEST_ROOT/browse-entries")
    local completed=$(wd_completion first_arg '')
    for (( i = 1; i <= ${#stored}; i++ )); do
        [[ $listed == *"point_$i  ->  ${expected[$i]}"* ]]
        assertTrue "list should abbreviate only the home component of path values" "$?"
        [[ $browsed == *"point_$i -> ${expected[$i]}"* ]]
        assertTrue "browse should preserve the full path and abbreviate only its home component" "$?"
        [[ $completed == *"point_$i:${expected[$i]}"* ]]
        assertTrue "completion descriptions should preserve literal paths and home boundaries" "$?"
    done
    [[ $browsed == *'last -> ~/Documents' ]]
    assertTrue "browse should include a final entry without a newline" "$?"
    [[ $listed == *'last  ->  ~/Documents' ]]
    assertTrue "list should include a final entry without a newline" "$?"
    assertEquals "path should load a final entry without a newline" \
        "$HOME/Documents" "$(wd path last)"
    [[ $completed == *'last:~/Documents' ]]
    assertTrue "completion should describe a final entry without a newline" "$?"
    assertEquals "completion should search a final entry without a newline" \
        "$HOME/Documents" "$(wd_completion second_arg last)"
}

test_path_consumers_and_cleanup()
{
    local HOME="$WD_TEST_ROOT/home"
    local original_pwd=$PWD
    local REPLY='caller value'
    local -a stored expected
    stored=(
        '~'
        '~/Library/Mobile Documents/com~apple~CloudDocs'
        '~/literal\n\t\\path::  '
        "$WD_TEST_ROOT/outside/foo~bar~baz"
        "${HOME}-backup"
        '~username/path'
    )
    expected=(
        "$HOME"
        "$HOME/Library/Mobile Documents/com~apple~CloudDocs"
        "$HOME"'/literal\n\t\\path::  '
        "$WD_TEST_ROOT/outside/foo~bar~baz"
        "${HOME}-backup"
        '~username/path'
    )
    command mkdir -p "$WD_TEST_ROOT"
    cd "$WD_TEST_ROOT" || return
    # Exercise open's argument without launching a desktop application.
    open() { print -r -- "$1"; }

    local i
    for (( i = 1; i <= ${#stored}; i++ )); do
        command mkdir -p "${expected[$i]}"
        command touch "${expected[$i]}/marker"
        printf 'point_%s:%s\n' "$i" "${stored[$i]}" >> "$WD_CONFIG"
        local output=$(wd ls "point_$i")
        [[ $output == *'marker'* ]]
        assertTrue "ls should use the correctly expanded path" "$?"
        assertEquals "open should receive the literal, correctly expanded path" \
            "${expected[$i]}" "$(wd open "point_$i")"
    done
    unfunction open

    wd "point_${#stored}"
    assertEquals "navigation should preserve a relative ~username path" \
        "$WD_TEST_ROOT/~username/path" "$PWD"
    cd "$WD_TEST_ROOT" || return

    local kept=$(< "$WD_CONFIG")
    # The old expansion would incorrectly retain this missing relative path.
    command mkdir -p "${HOME}username/missing"
    # Keep the last valid entry even when it has no terminating newline.
    printf 'missing:~username/missing\n%s' "$kept" > "$WD_CONFIG"
    wd -q clean --force
    assertEquals "cleanup should preserve valid paths literally and remove a missing ~username path" \
        "$kept" "$(< "$WD_CONFIG")"
    assertEquals "cleanup should preserve the caller's REPLY" \
        'caller value' "$REPLY"
    cd "$original_pwd" || return
}

test_export_home_paths()
{
    local HOME="$WD_TEST_ROOT/home"
    local WD_EXPORT=1
    local REPLY='caller value'
    local -a stored expected
    stored=(
        '~'
        '~/Library/Mobile Documents/com~apple~CloudDocs'
        '~/literal\n\t\\path  '
        "$WD_TEST_ROOT/outside/foo~bar~baz"
        '~username/path'
        "${HOME}-backup"
    )
    expected=(
        "$HOME"
        "$HOME/Library/Mobile Documents/com~apple~CloudDocs"
        "$HOME"'/literal\n\t\\path  '
        "$WD_TEST_ROOT/outside/foo~bar~baz"
        '~username/path'
        "${HOME}-backup"
    )
    local i export_point
    for (( i = 1; i <= ${#stored}; i++ )); do
        printf 'wd_export_%s:%s\n' "$i" "${stored[$i]}" >> "$WD_CONFIG"
    done
    printf 'invalid.name:~/Documents\nwd_export_last:~/Documents' >> "$WD_CONFIG"

    wd -q export
    assertEquals "export should preserve the caller's REPLY" \
        'caller value' "$REPLY"
    zmodload zsh/parameter
    for (( i = 1; i <= ${#stored}; i++ )); do
        export_point="wd_export_$i"
        assertEquals "WD_EXPORT should expand only the leading home component" \
            "${expected[$i]}" "${nameddirs[$export_point]}"
    done
    assertNull "WD_EXPORT should continue to skip invalid named-directory identifiers" \
        "${nameddirs[invalid.name]}"
    assertEquals "WD_EXPORT should include a final entry without a newline" \
        "$HOME/Documents" "${nameddirs[wd_export_last]}"

    # Restore the record separator before appending another warp point.
    printf '\n' >> "$WD_CONFIG"
    wd -q add wd_export_added
    assertEquals "WD_EXPORT should still export newly added warp points" \
        "$PWD" "${nameddirs[wd_export_added]}"
    assertEquals "add with WD_EXPORT should preserve the caller's REPLY" \
        'caller value' "$REPLY"
    for (( i = 1; i <= ${#stored}; i++ )); do
        unhash -d "wd_export_$i"
    done
    unhash -d wd_export_added wd_export_last
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

    local readonly_config="$WD_TEST_ROOT"'/readonly\n\tconfig'
    printf 'point:%s\n' "$PWD" > "$readonly_config"
    command chmod a-w "$readonly_config"
    # Root can still write to read-only files, so skip permission assertions.
    if [[ -w $readonly_config ]]; then
        startSkipping
    fi

    local operation output result
    for operation in add rm clean; do
        output=$(wd --config "$readonly_config" "$operation" point)
        result=$?
        assertEquals "$operation should fail for a read-only config" 1 "$result"
        [[ $output == *"'$readonly_config' is not writeable." ]]
        assertTrue "$operation should quote the config path without adding backslashes" "$?"
    done
    endSkipping
    command chmod u+w "$readonly_config"
    command rm "$readonly_config"
}


# Go go gadget
. ./shunit2/shunit2
