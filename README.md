wd
==

`wd` (warp directory) lets jump to custom directories in zsh, without using `cd`. Why? Because `cd` seems ineffecient when the folder is frequently visited or has a long path.

### Setup

 * Add `wd` alias to `.zshrc`:

        echo "alias wd='. /path/to/wd.sh'" >> ~/.profile


### Usage

 * Add warp point to current working directory:

        wd add dev

    If a previous warp point exists, use `add!` to overwrite it.

 * From other directory, warp to dev with:

        wd dev

 * You can warp back to previous directory, and so on with multiple puncticulations:

        wd ..
        wd ...

    This is a wrapper for zsh `dirs` function.
    You might need `setopt AUTO_PUSHD` in your `.zshrc` if you hare not using [oh-my-zshell](https://github.com/robbyrussell/oh-my-zsh)).

 * Remove warp point dev point:

        wd rm dev

 * List all warp points (stored in `~/.warprc`):

        wd ls

 * Print usage with no opts.
