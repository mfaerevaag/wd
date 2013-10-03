warp
====

###Setup

In .profile (or .bashrc/.zshrc):

    alias wrp='. /path/to/warp'


###Usage

Add warp point to current working directory:

    warp -a dev

From other directory, warp to dev with:

    warp -t dev

Delete warp point dev point:

    warp -d dev

List all warp points (stored in `~/.warprc`):

    warp -l

Print usage with no opts.
