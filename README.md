warp
====

###Setup

Add alias to .profile (or .bashrc/.zshrc):

    echo "alias wrp='. /path/to/warp'" >> ~/.profile


###Usage

Add warp point to current working directory:

    warp -a dev

From other directory, warp to dev with:

    warp dev

Remove warp point dev point:

    warp -r dev

List all warp points (stored in `~/.warprc`):

    warp -l

Print usage with no opts.
