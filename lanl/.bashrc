# .bashrc
#
# .bashrc is sourced only for non-login shells
#------------------------------------------------------------------------------#
#if test -f /etc/bashrc; then
#  source /etc/bashrc
#fi

# Making this next line active may break some commands (like scp) due to the
# extra verbosity.
#verbose=true

#------------------------------------------------------------------------------#
# CCS-2 standard setup
#------------------------------------------------------------------------------#

# If this is an interactive shell then the environment variable $-
# should contain an "i":
case ${-} in
*i*)
   export INTERACTIVE=true
   if test -n "${verbose}"; then
      echo "in ~/.bashrc"
   fi
   # If this is an interactive shell and DRACO_ENV_DIR isn't
   # set. Assume that we need to source the .bash_profile.
   if test -z "${DRACO_ENV_DIR}" && test -f ${HOME}/.bash_profile; then
     if test -n "${verbose}"; then
       echo "source $HOME/.bash_profile"
     fi
     source $HOME/.bash_profile
   fi

   # Set terminal title
   echo -ne "\033]0;${nodename}\007"
   ;;
*) # Not an interactive shell
  export INTERACTIVE=false
  export DRACO_ENV_DIR=$HOME/draco/environment
  ;;
esac

#------------------------------------------------------------------------------#
# Draco developer environment
#------------------------------------------------------------------------------#
if test -f ${DRACO_ENV_DIR}/bashrc/.bashrc; then
  if test -n "${verbose}"; then
    echo "source ${DRACO_ENV_DIR}/bashrc/.bashrc"
  fi
  source ${DRACO_ENV_DIR}/bashrc/.bashrc
fi

#------------------------------------------------------------------------------#
# User Customizations
#------------------------------------------------------------------------------#
if test "$INTERACTIVE" = true; then

  # aliases
  source ~/.bash_interactive

  # Set terminal title
  echo -ne "\033]0;${nodename}\007"
  # fancy prompt
  source ~/bash_wls.sh

  # home, scratchdir, modulefiles
  export CDPATH=.:/home/kellyt:/scratch:/scratch/kellyt:/scratch/vendors/Modules

fi
