wd
==

`wd` (*warp directory*) lets you jump to custom directories in zsh, without using `cd`. Why? Because `cd` seems ineffecient when the folder is frequently visited or has a long path.


### Setup

#### Automatic

Run either in terminal:

 * `curl -L https://github.com/mfaerevaag/wd/raw/master/install.sh | sh`

 * `wget --no-check-certificate https://github.com/mfaerevaag/wd/raw/master/install.sh -O - | sh`

#### Manual

 * Clone repo to your liking

 * Add `wd` alias to `.zshrc` (or .profile etc.):

        echo "alias wd='. /path/to/wd.sh'" >> ~/.zshrc


### Usage

 * Add warp point to current working directory:

        wd add test

    If a warp point with the same name exists, use `add!` to overwrite it.

 * From an other directory, warp to test with:

        wd test

 * You can warp back to previous directory, and so on, with the puncticulation syntax:

        wd ..
        wd ...

    This is a wrapper for the zsh `dirs` function.
    You might need `setopt AUTO_PUSHD` in your `.zshrc` if you hare not using [oh-my-zshell](https://github.com/robbyrussell/oh-my-zsh)).

 * Remove warp point test point:

        wd rm test

 * List warp points to current directory (stored in `~/.warprc`):

        wd show

 * List all warp points (stored in `~/.warprc`):

        wd ls

 * Print usage with no opts or the `help` argument.


### Finally

If you have issues, feedback or improvements, don't hesitate to report it, fork or submit a pull request.

Credit to [altschuler](https://github.com/altschuler) for awesome idea.

Hope you enjoy!
