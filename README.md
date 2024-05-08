# Git Aware Prompt (tony-sol's fork)

Working with Git and its great branching/merging features is
amazing. Constantly switching branches can be confusing though as you have to
run `git status` to see which branch you're currently on.

The solution to this is to have your terminal prompt display the current
branch. There are a [number][1] [of][2] [articles][3] [available][4] online
about how to achieve this. This project is an attempt to make an easy to
install/configure solution.

[1]: http://aaroncrane.co.uk/2009/03/git_branch_prompt/
[2]: http://railstips.org/2009/2/2/bedazzle-your-bash-prompt-with-git-info
[3]: http://techblog.floorplanner.com/2008/12/14/working-with-git-branches/
[4]: http://www.intridea.com/2009/2/2/git-status-in-your-prompt


## Overview

If you `cd` to a Git working directory, you will see the current Git branch
name displayed in your terminal prompt. When you're not in a Git working
directory, your prompt works like normal.


**This fork by tony-sol also:**
- shows how many stashes you have on **stash** (when the top stash entry was made on the current commit or the current branch).
- provided [colors.sh](https://github.com/tony-sol/git-aware-prompt/raw/master/colors.sh) won't be loaded for zsh due to performance issue, use `autoload -U colors && colors` and example bellow instead.


![Git Branch in Prompt](https://github.com/tony-sol/git-aware-prompt/raw/master/preview.png)

> `≡2` indicates that there are 2 entries on the stash, and last one related to current branch or commit.
>
> `≋3` indicates that there are 3 entries on the stash.
>
> `<3` indicates that the local branch is 3 commits behind the upstream (remote) branch, and could/should be pulled.
>
> `?1` indicates that there is 1 untracked file in the tree.
>
> `+1` indicates that one file is staged for comitting.
>
> `>1` indicates that the local branch has 1 commit which has not yet been pushed to the upstream.
>
> `*1` indicates that the branch is dirty, with 1 file modified but not committed.
>
> `#` would indicate that `git status` has taken too long, so the markers are not shown.
>
>  In that situation, `git status` will continue running in the background, so after a few moments, hitting `<Enter>` again should give you an up-to-date summary.

We also have some indicators for the current branch:

> `[branch_name]` means you are on a branch with an upstream
>
> `(branch_name)` means you are on a branch without an upstream
>
> `{branch_name\mode}` means you are in the middle of a merge, rebase, cherry-pick, revert or bisect
>
> `<commit_id>` means you are detached on the given commit, tag, or remote branch

The symbols (or "markers") can be changed by editing the `prompt.sh` file directly (and reloading it of course).  The numbers or the markers can be omitted by removing the `_count` or `_mark` variables from the `PS1` prompt below.


## See Also

- The [joeytwiddle's git-aware-prompt](https://github.com/joeytwiddle/git-aware-prompt) from which this version is forked

- The [original git-aware-prompt](https://github.com/jimeh/git-aware-prompt) by jimeh

- The [prompt now distributed with git](https://github.com/git/git/blob/master/contrib/completion/git-prompt.sh) offers a `GIT_PS1_SHOWUPSTREAM` option.

- Zsh now ships with [vcs_info](https://git-scm.com/book/tr/v2/Appendix-A%3A-Git-in-Other-Environments-Git-in-Zsh) which works for a variety of version control systems.  (Unfortunately the docs for this are a big gnarly.)

- [Oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh) has its own [git-prompt](https://github.com/robbyrussell/oh-my-zsh/blob/master/plugins/gitfast/git-prompt.sh).  (It has 500 lines compared to our 200.)

- Inspiration for this fork came from [git-branch-status](https://gist.github.com/jehiah/1288596) by jehiah (a command, not a prompt)

- [pure](https://github.com/sindresorhus/pure) prompt by sindresorhus includes good git support (for zsh only)

- [liquidprompt](https://github.com/nojhan/liquidprompt) includes some git support (for bash and zsh)


## Installation

Clone the project to a shell configuration folder in your home directory, e.g.:

```bash
cd "${ZDOTDIR}/extensions/"
git clone git://github.com/tony-sol/git-aware-prompt.git
```

Edit your shell rc file (e.g. `~/.bash_profile`, `~/.profile`, `~/.bashrc`, `~/.zshrc`, `~/.zprofile`, etc.) and add the following to the top:

```bash
source "${ZDOTDIR}/extensions/git-aware-prompt/main.sh"
```


## Configuring

Once installed, there will be several new variables
available to use in the `PS1`(or `PROMPT`, `RPROMPT`) environment variable:
 * `$git_ahead_count`
 * `$git_ahead_mark`
 * `$git_behind_count`
 * `$git_behind_mark`
 * `$git_branch`
 * `$git_dirty_mark`
 * `$git_dirty_count`
 * `$git_staged_count`
 * `$git_staged_mark`
 * `$git_stash_count`
 * `$git_stash_mark`
 * `$git_unknown_count`
 * `$git_unknown_mark`

If you want to know more about how to customize your prompt, I recommend
this article: [How to: Change / Setup bash custom prompt (PS1)][how-to]

[how-to]: http://www.cyberciti.biz/tips/howto-linux-unix-bash-shell-setup-prompt.html


### Suggested Prompts

Below are a few suggested prompt configurations. Simply paste the code at the
end of the same file you pasted the installation code into earlier.


#### macOS (zsh)

```bash
export RPROMPT='%{$fg_bold[green]%}$git_ahead_mark$git_ahead_count%{$fg_bold[red]%}$git_behind_mark$git_behind_count%{$fg_bold[cyan]%}$git_stash_mark$git_stash_count%{$fg_bold[yellow]%}$git_dirty_mark$git_dirty_count%{$fg_bold[blue]%}$git_staged_mark$git_staged_count%{$fg_bold[magenta]%}$git_unknown_mark$git_unknown_count%{$reset_color%}%{$fg[cyan]%}$git_branch%{$reset_color%}'
```


#### Ubuntu (bash)

```bash
export PS1="\${debian_chroot:+(\$debian_chroot)}\u@\h:\w\[$txtcyn\]\$git_branch\[$bldgrn\]\$git_ahead_mark\$git_ahead_count\[$txtrst\]\[$bldred\]\$git_behind_mark\$git_behind_count\[$txtrst\]\[$bldyellow\]\$git_stash_mark\$git_stash_count\[$txtrst\]\[$txtylw\]\$git_dirty_mark\$git_dirty_count\[$txtrst\]\[$txtcyn\]\$git_staged_mark\$git_staged_count\[$txtrst\]\[$txtblu\]\$git_unknown_mark\$git_unknown_count\[$txtrst\]\$ "
```


## Updating

Assuming you followed the default installation instructions and cloned this
repo to `"${ZDOTDIR}/extensions/git-aware-prompt"`:

```bash
cd "${ZDOTDIR}/extensions/git-aware-prompt"
git pull
```


## Usage Tips

To view other user's tips, please check the
[Usage Tips](https://github.com/jimeh/git-aware-prompt/wiki/Usage-Tips) wiki
page. Or if you have tips of your own, feel free to add them :)


## License

[CC0 1.0 Universal](http://creativecommons.org/publicdomain/zero/1.0/)
