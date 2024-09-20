# Other things we could count:
# - Number of conflicts
# - Whether we are on a merge or a rebase?

is_inside_git_dir() {
  echo "$PWD" | grep "/\.git\(/\|$\)" >/dev/null
}

find_git_branch() {
  # Based on: http://stackoverflow.com/a/13003854/170413
  local branch
  local upstream
  local is_branch
  local git_dir
  local special_state
  if branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null); then
    if [[ "$branch" == "HEAD" ]]; then
      # Check for tag.  From jordi-adell's branch.
      #branch=$(git name-rev --tags --name-only $(git rev-parse HEAD))
      #if ! [[ $branch == *"~"* || $branch == *" "* || $branch == undefined ]]; then
      #  branch="+${branch}"
      # Or check for tag, by dafeder (just trying this alternative out)
      if tag=$(git describe --exact-match --tags >&1 2> /dev/null); then
        branch="+$tag"
      else
        # If it a remote branch, show that (this can also produce tags/...)
        branch=$(git name-rev --name-only HEAD | sed 's+^remotes/++')
        # But name-rev will also return if it is a few steps back from a remote branch, which sucks, so don't display that
        if [[ "$branch" == "undefined" ]] || grep '[~]' <<< "$branch" >/dev/null; then
          #branch='<detached>'
          # Or show the short hash
          branch='#'$(git rev-parse --short HEAD 2> /dev/null)
          # Or the long hash, with no leading '#'
          #branch=$(git rev-parse HEAD 2> /dev/null)
        fi
      fi
    else
      # This is a named branch
      is_branch=true
      upstream=$(git rev-parse '@{upstream}' 2> /dev/null)
    fi
    if is_inside_git_dir; then
      git_dir="${PWD%\/\.git*}/.git"
    else
      git_dir="$(git rev-parse --show-toplevel)/.git"
    fi
    if [[ -d "$git_dir/rebase-merge" ]] || [[ -d "$git_dir/rebase-apply" ]]; then
      special_state=rebase
    elif [[ -f "$git_dir/MERGE_HEAD" ]]; then
      special_state=merge
    elif [[ -f "$git_dir/CHERRY_PICK_HEAD" ]] || [[ -f "$git_dir/sequencer/todo" ]]; then
      special_state=pick
    elif [[ -f "$git_dir/REVERT_HEAD" ]]; then
      special_state=revert
    elif [[ -f "$git_dir/BISECT_LOG" ]]; then
      special_state=bisect
    fi
    if [[ -n "$special_state" ]]; then
      git_branch="{$branch\\$special_state}"
    elif [[ -n "$is_branch" && -n "$upstream" ]]; then
      git_branch="[$branch]"     # Branch has an upstream
    elif [[ -n "$is_branch" ]]; then
      git_branch="($branch)"     # Branch has no upstream
    else
      git_branch="<$branch>"     # Detached
    fi
  else
    git_branch=""
  fi
}

find_git_dirty() {
  git_dirty_mark=''
  git_dirty_count=''
  git_staged_mark=''
  git_staged_count=''
  git_unknown_mark=''
  git_unknown_count=''

  # Optimization.  Requires that find_git_branch always runs before find_git_dirty in PROMPT_COMMAND or zsh's precmd hook.
  if [[ -z "$git_branch" ]] || is_inside_git_dir ; then
    return
  fi

  # We run `git status` in the background, but stop waiting for it if it is taking too long to complete.
  # This can happen on machines with slow disc access, especially when first entering a large repository.
  # We do not actually cache the *result* of `git status`, instead we trust the machine to fill its disk cache with file info from the working tree.
  # (Caching the result would risk displaying out-of-date stats.  We want to provide up-to-date stats, or no stats.)
  # Once `git status` has completed once, all the file info should be in the disk cache, so later runs of `git status` should complete within the time limit.
  # If this is not happening, increase the `seq 1 5` below to `seq 1 10`.

  local gs_done_file=/tmp/done_gs.$USER.$$
  local gs_porc_file=/tmp/gs_porc.$USER.$$
  # Because we background the process but we don't always wait for it, there may be a done_file from a previous fork.  If we don't remove it, it could cause us to stop waiting prematurely.
  'rm' -f "$gs_done_file"

  # If the MONITOR option is set, we need to unset it, to stop zsh from spamming four job info messages!
  # We do this in a subshell so we won't affect the setting in the outer (user's) shell.
  # CONSIDER: Instead of subshell, we could check the value of MONITOR before, and restore it afterwards.
  (
    [[ -n "$ZSH_NAME" ]] && unsetopt MONITOR
    # Start running the git status process in the background
    # -uall lists files below un-added folders; without it only the parent folder is listed
    ( git status --porcelain -uall 2> /dev/null > "$gs_porc_file" ; touch "$gs_done_file" ) &
  )
  local gs_shell_pid="$!"
  (
    # This is needed to stop zsh from spamming four job info messages!
    [[ -n "$ZSH_NAME" ]] && unsetopt MONITOR

    # Wait for that process to complete, or give up waiting if the timeout is reached.
    # This number defines the length of the timeout (in tenths of a second).
    for X in {1..4}; do   # Or increase to 10 for 1 second timeout
      sleep 0.1
      [[ -f "$gs_done_file" ]] && exit
    done
    # If the timeout is reached, kill the `git status`.
    # Killing the parent (...)& shell is not enough; we also need to kill the child `git status` process running inside it.
    # We must do this before killing the parent, because killing the parent first would leave the orphaned process with PPID 1.
    #pkill -P "$gs_shell_pid"
    #kill "$gs_shell_pid"
    # We may want to add 2>/dev/null to the two lines above, in case the process completes *just* before we issue the kill signal.
  )

  # This should be a simpler way to do the same as the above.
  # Crucially we don't want to stop the git status process if it times out, we want to let it continue to run in the background.
  # Unfortunately it seemed that when I sent SIGHUP to git status, it didn't continue in the background, but it actually stopped running.
  # If I sent SIGCONT after the timeout, it would remain running in the foreground, which is not what we wanted.
  #timeout -s HUP 0.4s git status --porcelain 2> /dev/null > "$gs_porc_file"
  #[ "$?" = 0 ] && touch "$gs_done_file"

  if [[ ! -f "$gs_done_file" ]]; then
    git_dirty_mark='#'
    return
  fi
  'rm' -f "$gs_done_file"

  # Without a timeout:
  #git status --porcelain 2> /dev/null > "$gs_porc_file"

  # All dirty files (modified and untracked)
  #git_dirty_count=$(cat "$gs_porc_file" | wc -l)
  # Only modified files
  #git_dirty_count=$(grep -c -v '^??' "$gs_porc_file")
  # Only modified files which have not been staged.  The second grep hides staged [M]odified files, staged [A]dded files, staged [D]eletes and staged [R]enames.
  # Whitelist: Hide things which we know mean cleanly staged.
  #git_dirty_count=$(grep -v '^??' "$gs_porc_file" | grep -c -v '^[AMDR] ')
  # Blacklist: Hide things which we think mean cleanly staged.
  # That is anything with a space in the second column, or in the case of staged resolved merge conflicts, 'UU'.
  git_dirty_count=$(grep -v '^??' "$gs_porc_file" | grep -c -v '^\([^ ?] \|UU\)')
  if [[ "$git_dirty_count" > 0 ]]; then
    git_dirty_mark='*'
  else
    git_dirty_count=''
  fi

  # Untracked/unknown files
  git_unknown_count=$(grep -c "^??" "$gs_porc_file")
  if [[ "$git_unknown_count" > 0 ]]; then
    git_unknown_mark='?'
  else
    git_unknown_count=''
  fi

  # How many files are staged?
  # Whitelist:
  #git_staged_count=$(grep -c '^[AMDR].' "$gs_porc_file")
  # Permissive (show anything which appears to be staged):
  git_staged_count=$(grep -c '^[^ ?].' "$gs_porc_file")
  if [[ "$git_staged_count" > 0 ]]; then
    git_staged_mark='+'
  else
    git_staged_count=''
  fi

  'rm' -f "$gs_porc_file"
}

find_git_ahead_behind() {
  git_ahead_count=''
  git_ahead_mark=''
  git_behind_count=''
  git_behind_mark=''
  if [[ -z "$git_branch" ]] || is_inside_git_dir ; then
    return
  fi
  local local_branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
  if [[ -n "$local_branch" ]] && [[ "$local_branch" != "HEAD" ]]; then
    local upstream_branch=$(git rev-parse --abbrev-ref "@{upstream}" 2> /dev/null)
    # If we get back what we put in, then that means the upstream branch was not found.  (This was observed on git 1.7.10.4 on Ubuntu)
    [[ "$upstream_branch" = "@{upstream}" ]] && upstream_branch=''
    # If the branch is not tracking a specific remote branch, then assume we are tracking origin/[this_branch_name]
    [[ -z "$upstream_branch" ]] && upstream_branch="origin/$local_branch"
    if [[ -n "$upstream_branch" ]]; then
      # These always return a number
      #git_ahead_count=$(git rev-list --left-right ${local_branch}...${upstream_branch} 2> /dev/null | grep -c '^<')
      #git_behind_count=$(git rev-list --left-right ${local_branch}...${upstream_branch} 2> /dev/null | grep -c '^>')
      # If the upstream does not exist, these will return ""
      git_ahead_count=$(git rev-list --count ${upstream_branch}..${local_branch} 2> /dev/null)
      git_behind_count=$(git rev-list --count ${local_branch}..${upstream_branch} 2> /dev/null)
      if [[ "$git_ahead_count" -gt 0 ]]; then
        git_ahead_mark='>'
      else
        git_ahead_count=''
      fi
      if [[ "$git_behind_count" -gt 0 ]]; then
        git_behind_mark='<'
      else
        git_behind_count=''
      fi
    fi
  fi
}

find_git_stash_status() {
  git_stash_count=''
  git_stash_mark=''
  if [[ -z "$git_branch" ]] || is_inside_git_dir ; then
    return
  fi
  local stash=$(git stash list --format='%gs')
  git_stash_count=$(echo -ne "$stash" | grep -c '^')
  if [[ $git_stash_count -gt 0 ]]; then
    local last_stash=$(echo -ne "$stash" | head -1)
    local stashed_commit=$(echo -ne "$last_stash" | cut -d ':' -f 2 | cut -d ' ' -f 2)
    local stashed_branch=$(echo -ne "$last_stash" | cut -d ':' -f 1 | sed 's+.* ++')
    local current_commit=$(git rev-parse --short HEAD 2> /dev/null)
    local current_branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
    # This sets different stash marker in case of
	# either the current commit or the current branch name is mentioned in the top stack entry.
    if [[ "$stashed_commit" = "$current_commit" ]] || [[ -n "$current_branch" ]] && [[ "$stashed_branch" = "$current_branch" ]]; then
      git_stash_mark='≡'
    else
      git_stash_mark='≋'
    fi
  else
    git_stash_count=''
  fi
}

PROMPT_COMMAND="find_git_branch; find_git_dirty; find_git_ahead_behind; find_git_stash_status; ${PROMPT_COMMAND:-}"

# The above works for bash.  For zsh we need this:
if [[ -n "$ZSH_NAME" ]]; then
  setopt PROMPT_SUBST

  autoload add-zsh-hook
  add-zsh-hook precmd find_git_branch
  add-zsh-hook precmd find_git_dirty
  add-zsh-hook precmd find_git_ahead_behind
  add-zsh-hook precmd find_git_stash_status
fi
