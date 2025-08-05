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

  # mark all defined functions for export
  # declare -fx reloadkeys keychain unix2dos dos2unix eapde

  [[ "${verbose:=false}" == "true" ]] && echo "in ~/.bash_functions ... done"
fi

#------------------------------------------------------------------------------#
# End .bash_functions
#------------------------------------------------------------------------------#
