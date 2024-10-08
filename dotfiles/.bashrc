# ~/.bashrc: executed by bash(1) for non-login shells.
#
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc) for examples
# ------------------------------------------------------------------------------------------------ #

# Making this next line active may break some commands (like scp) due to the
# extra verbosity.
verbose=true

if [[ -f /etc/bashrc && `uname -n` =~ ccscs[1-9] ]]; then
  [[ ${verbose:-false} == "true" ]] && echo "source /etc/bashrc"
  source /etc/bashrc
fi


# ------------------------------------------------------------------------------------------------ #
# CCS-2 standard setup
# ------------------------------------------------------------------------------------------------ #

# If this is an interactive shell then the environment variable $- should contain an "i":
case ${-} in
*i*)
   export INTERACTIVE=true
   if [[ "${verbose:=false}" ==  "true" ]]; then echo "in ~/.bashrc"; fi
   # If this is an interactive shell and DRACO_ENV_DIR isn't set. Assume that we need to source the
   # .bash_profile.
   target=`uname -n`
   case ${target} in
     t[rt]-rfe* | cp-rlogin* )
       # On an initial loginc, .bashrc is sources first and then .bash_profile
       if ! [[ ${SHLVL} == 1 ]]; then source ~/.bash_profile; fi
       ;;
     *)
       if [[ -z ${CI} ]] || \
             [[ `alias bash_aliases_pragma_once 2>&1 | grep -c "bash: alias"` != 0 ]]; then
         source $HOME/.bash_profile
       fi
       ;;
   esac
   ;;
*)
    # Not an interactive shell
    export INTERACTIVE=false
    export DRACO_ENV_DIR=$HOME/draco/environment

    target="`uname -n | sed -e s/[.].*//`"
    case ${target} in
      t[rt]-fey[0-9] | t[rt]-login[0-9])
        alias salloc='salloc --gres=craynetwork:0 --x11'
        ;;
      *)
        modcmd=`declare -f module`
        # If not found, look for it in /usr/share/Modules (Toss)
        if [[ ! ${modcmd} ]]; then
          if [[ -f /usr/share/lmod/lmod/init/bash ]]; then
            source /usr/share/lmod/lmod/init/bash
#          else
#            echo "ERROR: The module command was not found. No modules will be loaded."
          fi
        fi
        modcmd=`declare -f module`
        ;;
    esac

    # end INTERACTIVE=false case
    ;;
esac

# ------------------------------------------------------------------------------------------------ #
# User Customizations
# ------------------------------------------------------------------------------------------------ #
if [[ "$INTERACTIVE" == "true" ]]; then

  # home, scratchdir, modulefiles
  export CDPATH=.:$HOME
  extra_dirs="/scratch /scratch/$USER /lustre/ttscratch1"
  for dir in $extra_dirs; do
    if [[ -d $dir ]]; then export CDPATH=$CDPATH:$dir; fi
  done
  add_to_path $HOME/bin PATH
  case $target in
    ccscs*)
    add_to_path /ccs/opt/keychain-2.8.5 PATH
    rm_from_path /home/kellyt/.composer/vendor/bin PATH
    rm_from_path /usr/lib64/qt-3.3/bin PATH
    rm_from_path /opt/rh/php55/root/usr/bin PATH
    rm_from_path /opt/rh/php55/root/usr/sbin PATH
    ;;
  esac
  if [[ "${verbose}" == "true" ]]; then echo "done with $HOME/.bashrc"; fi
fi

# ------------------------------------------------------------------------------------------------ #
# End ~/.bashrc
# ------------------------------------------------------------------------------------------------ #
