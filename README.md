wd
==

`wd` (*warp directory*) lets you jump to custom directories in zsh, without using `cd`. Why? Because `cd` seems ineffecient when the folder is frequently visited or has a long path.


### Setup

### oh-my-zsh

`wd` comes bundles with [oh-my-zshell](https://github.com/robbyrussell/oh-my-zsh)!

Just add the plugin in your `~/.zshrc` file:

    plugins=(... wd)


#### Automatic

Run either in terminal:

 * `curl -L https://github.com/mfaerevaag/wd/raw/master/install.sh | sh`

 * `wget --no-check-certificate https://github.com/mfaerevaag/wd/raw/master/install.sh -O - | sh`


#### Manual

 * Clone this repo to your liking

 * Add `wd` function to `.zshrc` (or `.profile` etc.):


        wd() {
            . ~/paht/to/wd/wd.sh
        }


#### Completion

If you're NOT using [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh) and you want to utelize the zsh-completion feature, you will also need to add the path to your `wd` installation (`~/bin/wd` if you used the automatic installer) to your `fpath`. E.g. in your `~/.zshrc`:

    fpath=(~/path/to/wd $fpath)

Also, you may have to force a rebuild of `zcompdump` by running:

    $ rm -f ~/.zcompdump; compinit



### Usage

 * Add warp point to current working directory:

        $ wd add foo

    If a warp point with the same name exists, use `add!` to overwrite it.

    Note, a warp point cannot contain colons, or only consist of only spaces and dots. The first will conflict in how `wd` stores the warp points, and the second will conflict other features, as below.

 * From an other directory (not necessarily), warp to `foo` with:

        $ wd foo

 * You can warp back to previous directory, and so on, with this dot syntax:

        $ wd ..
        $ wd ...

    This is a wrapper for the zsh `dirs` function.
    (You might need `setopt AUTO_PUSHD` in your `.zshrc` if you hare not using [oh-my-zshell](https://github.com/robbyrussell/oh-my-zsh)).

 * Remove warp point test point:

        $ wd rm foo

 * List all warp points (stored in `~/.warprc`):

        $ wd ls

 * List warp points to current directory

        $ wd show

 * Print usage with no opts or the `help` argument.


### License

The project is licensed under the [MIT-license](https://github.com/mfaerevaag/wd/blob/master/LICENSE).


### Finally

If you have issues, feedback or improvements, don't hesitate to report it or submit a pull-request.

Credit to [altschuler](https://github.com/altschuler) for awesome idea.

Hope you enjoy!
