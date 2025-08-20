# .bashrc_functions
#
# .bashrc_functions is sourced by interactive shells from
# .bash_profile and .bashrc
#------------------------------------------------------------------------------#

# pragma once
if [[ `type bash_functions_pragma_once 2>&1 | grep -c "bash: type: "` != 0 ]]; then
  function bash_functions_pragma_once () {
    echo "bfpo"
  }
  [[ "${verbose:=false}" == "true" ]] && echo "in ~/.bash_functions"

  #------------------------------------------------------------------------------#
  # User Customizations
  #------------------------------------------------------------------------------#

  # Functions ----------------------------------------------------------------#
  function eapde ()
  {
    export EAP_INHIBIT_KSM=1
    export L_EAP_ENV=new
    if [[ "${LMOD_CMD+set}" == "set" ]]; then
      module load uc/unuse
      echo "Resetting lmod module cache"
      module --ignore_cache avail &> /dev/null
    fi
    local eapbashrc=$(/usr/bin/ls -1 $HOME/*/eap.xrage/tools.xrage/Environment/.bashrc)
    echo "eapbashrc = $eapbashrc"
    source "${eapbashrc}"
    module list
  }

  function keychain()
  {
    unset keychain
    local kc=`which keychain`
    if [[ $? != 0 ]]; then
      kc=/ccs/opt/bin/keychain
      if ! [[ -x $kc ]]; then
        echo "Keychain not found" && exit 1
      fi
    fi
    $kc --nogui ~/.ssh/id_rsa
    source ~/.keychain/${HOSTNAME}-sh
  }

  # function gitup {
  #   # save current state
  #   local curr_branch=$(git branch | grep \* | sed -e 's/.*[ ]//')
  #   local dirty=$(git diff --name-only | wc -l)
  #   local has_upstream=$(git remote -v | grep -c upstream)
  #   # clean the current state
  #   [[ ${dirty} != 0 ]] && run "git stash"
  #   # Fetch the updates
  #   run "git fetch --all -p"
  #   local stalebranches=$(git branch -av | grep '\[gone]' | awk '{print $1}')
  #   for b in $stalebranches; do
  #     [[ $curr_branch != $b ]] && run "git branch -D $b"
  #   done
  #   # Update branches that track upstream
  #   if [[ "${has_upstream}" -gt 0 ]]; then
  #     local upstream_branches=$(git branch -a | grep upstream | sed -e 's%remotes/upstream/%%')
  #     for b in $upstream_branches; do
  #       if [[ $b =~ "develop" ]] || [[ $b =~ "main" ]] || [[ $b =~ "master" ]]; then
  #         if [[ $(git branch -a | grep -c " ${b}") -gt 0 ]]; then
  #           git checkout $b
  #         else
  #           git checkout -b $b upstream/$b
  #         fi
  #         run "git reset --hard upstream/$b"
  #       fi
  #     done
  #   else
  #     # origin points to the upstream (no fork)
  #     local upstream_branches=$(git branch -a | grep origin | sed -e 's%remotes/origin/%%')
  #     for b in $upstream_branches; do
  #       if [[ $b =~ "develop" ]] || [[ $b =~ "main" ]] || [[ $b =~ "master" ]]; then
  #         if [[ $(git branch -a | grep -c " ${b}") -gt 0 ]]; then
  #           git checkout $b
  #         else
  #           git checkout -b $b origin/$b
  #         fi
  #         run "git reset --hard origin/$b"
  #       fi
  #     done
  #   fi
  #   # Restore state
  #   run "git checkout $curr_branch"
  #   [[ ${dirty} != 0 ]] && run "git stash pop" || true
  # }

  # Written by Chatgpt-5
  function gitup() {
    # error handling change (exit status is the first non-zero value)
    set -o pipefail

    # 0) Ensure we're in a Git repo
    if ! git rev-parse -q --is-inside-work-tree >/dev/null 2>&1; then
      echo "Not inside a Git repository."
      return 1
    fi

    # 1) Dirty check (staged, unstaged, and untracked)
    if [[ -n "$(git status --porcelain=v1 --untracked-files=all)" ]]; then
      echo "Your working tree is dirty. Please commit, stash, or clean changes first."
      return 1
    fi

    # 2) Fetch updates from all remotes, prune deleted branches, and tags too
    echo "Fetching from all remotes (with prune)…"
    if ! git fetch --all --prune --tags; then
      echo "Fetch failed."
      return 1
    fi

    # Determine current branch (may be detached)
    current_branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
    if [[ -z "$current_branch" ]]; then
      echo "Detached HEAD. Skipping merge step."
    else
      # 3) If current branch tracks an upstream and is behind/diverged, merge upstream
      upstream_ref="$(git for-each-ref --format='%(upstream:short)' "refs/heads/$current_branch")"
      if [[ -n "$upstream_ref" ]]; then
        # Count commits: left = behind (upstream..HEAD), right = ahead (HEAD..upstream)
        read -r behind ahead < <(git rev-list --left-right --count "${upstream_ref}...HEAD" 2>/dev/null | awk '{print $1, $2}')
        behind=${behind:-0}
        ahead=${ahead:-0}

        if (( behind > 0 )); then
          echo "Branch '$current_branch' is behind its upstream (${behind} behind, ${ahead} ahead). Merging '${upstream_ref}'…"
          if ! git merge --no-edit --no-ff "${upstream_ref}"; then
            echo "Merge failed. Resolve conflicts and re-run if needed."
            return 1
          fi
        else
          echo "Branch '$current_branch' is up to date with its upstream (or only ahead). No merge needed."
        fi
      else
        echo "Branch '$current_branch' has no upstream configured. Skipping merge step."
      fi
    fi

    # 4) Delete local branches whose tracked upstream was deleted on the remote
    echo "Checking for local branches whose upstream is gone…"
    while IFS=$'\t' read -r branch upstream; do
      [[ -z "$upstream" ]] && continue              # no tracking upstream
      [[ "$branch" == "$current_branch" ]] && continue  # never delete the current branch

      # If the remote-tracking ref for the upstream doesn't exist anymore, it's gone.
      if ! git show-ref --verify --quiet "refs/remotes/${upstream}"; then
        echo "Upstream for '$branch' (${upstream}) is gone on the remote. Deleting local branch…"
        if ! git branch -d "$branch" 2>/dev/null; then
          echo "  Couldn't delete '$branch' with -d (probably unmerged). Forcing delete with -D."
          git branch -D "$branch" || {
            echo "  Failed to delete '$branch'. Please inspect manually."
            # don't exit; continue trying other branches
          }
        fi
      fi
    done < <(git for-each-ref --format='%(refname:short)%09%(upstream:short)' refs/heads)

    echo "Done."
  }

  # mark all defined functions for export
  # declare -fx reloadkeys keychain unix2dos dos2unix eapde

  [[ "${verbose:=false}" == "true" ]] && echo "in ~/.bash_functions ... done"
fi

#------------------------------------------------------------------------------#
# End .bash_functions
#------------------------------------------------------------------------------#
