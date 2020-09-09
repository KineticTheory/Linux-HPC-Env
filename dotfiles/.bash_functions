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
  if test -n "${verbose}"; then echo "source $HOME/.bash_functions"; fi

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
    local kc=`which keychain`
    if [[ $? != 0 ]]; then
      kc=/scratch/vendors/keychain-2.8.5/keychain
      if ! [[ -x $kc ]]; then
        echo "Keychain not found" && exit 1
      fi
    fi
    $kc ~/.ssh/id_rsa
    source ~/.keychain/${HOSTNAME}-sh
  }

  function reloadkeys()
  {
    if [[ `ssh-add -L | wc -l` = 0 ]]; then
      MYHOSTNAME="`uname -n`"
      if [[ -x $VENDOR_DIR/keychain-2.8.5/keychain ]]; then
        eval "$VENDOR_DIR/keychain-2.8.5/keychain --agents ssh $HOME/.ssh/id_rsa"
      fi
      run "source $HOME/.keychain/$MYHOSTNAME-sh"
    fi
  }

  # mark all defined functions for export
  # declare -fx reloadkeys keychain unix2dos dos2unix eapde

  if test -n "${verbose}"; then echo "done with $HOME/.bash_functions"; fi
fi

#------------------------------------------------------------------------------#
# End .bash_functions
#------------------------------------------------------------------------------#
