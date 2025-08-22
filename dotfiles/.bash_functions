# .bashrc_functions
# - sourced by interactive shells from .bash_profile and .bashrc
#--------------------------------------------------------------------------------#

# pragma once
if [[ `type bash_functions_pragma_once 2>&1 | grep -c "bash: type: "` != 0 ]]; then
  function bash_functions_pragma_once () {
    echo "bfpo"
  }
  [[ "${verbose:=false}" == "true" ]] && echo "in ~/.bash_functions"

  #------------------------------------------------------------------------------#
  # User Customizations
  #------------------------------------------------------------------------------#

  # Functions -------------------------------------------------------------------#
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

    # Determine current branch (must not be detached)
    current_branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
    if [[ -z "$current_branch" ]]; then
      echo "Detached HEAD. Refusing to proceed."
      return 1
    fi

    # Resolve / set upstream
    upstream_ref="$(git for-each-ref --format='%(upstream:short)' "refs/heads/$current_branch")"

    # If no upstream yet, try origin/<branch-name>
    if [[ -z "$upstream_ref" ]]; then
      candidate_upstream="origin/${current_branch}"
      if git show-ref --verify --quiet "refs/remotes/${candidate_upstream}"; then
        echo "No upstream configured. Setting upstream to '${candidate_upstream}'."
        if ! git branch --set-upstream-to="${candidate_upstream}" "$current_branch"; then
          echo "Failed to set upstream to ${candidate_upstream}."
          return 1
        fi
        upstream_ref="$candidate_upstream"
      else
        echo "No upstream configured and '${candidate_upstream}' does not exist on the remote."
        echo "Cannot make local branch exactly match a non-existent remote."
        return 1
      fi
    fi

    # 3) Force local branch to exactly match upstream
    echo "Hard resetting '${current_branch}' to '${upstream_ref}'…"
    if ! git reset --hard "${upstream_ref}"; then
      echo "Hard reset failed."
      return 1
    fi

    # Remove untracked files/dirs (keeps ignored files). Use -fdx to also remove ignored files
    # if desired.
    echo "Cleaning untracked files and directories (ignored files preserved)…"
    if ! git clean -fd; then
      echo "git clean failed."
      return 1
    fi

    # 4) Delete local branches whose tracked upstream was deleted on the remote
    echo "Checking for local branches whose upstream is gone…"
    while IFS=$'\t' read -r branch upstream; do
      [[ -z "$upstream" ]] && continue                  # no tracking upstream
      [[ "$branch" == "$current_branch" ]] && continue  # never delete the current branch

      if ! git show-ref --verify --quiet "refs/remotes/${upstream}"; then
        echo "Upstream for '$branch' (${upstream}) is gone on the remote. Deleting local branch…"
        if ! git branch -d "$branch" 2>/dev/null; then
          echo "  Couldn't delete '$branch' with -d (probably unmerged). Forcing delete with -D."
          git branch -D "$branch" || echo "  Failed to delete '$branch'. Please inspect manually."
        fi
      fi
    done < <(git for-each-ref --format='%(refname:short)%09%(upstream:short)' refs/heads)

    echo "Done. Local branch '${current_branch}' now matches '${upstream_ref}'."
  }

  # ----- report at the end of the pragma_once block -----
  [[ "${verbose:=false}" == "true" ]] && echo "in ~/.bash_functions ... done"
fi

#------------------------------------------------------------------------------#
# End .bash_functions
#------------------------------------------------------------------------------#
