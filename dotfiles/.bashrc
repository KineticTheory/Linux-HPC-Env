# ~/.bashrc: executed by bash(1) for non-login shells.
#
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
#------------------------------------------------------------------------------#

if [[ -f /etc/bashrc ]]; then
  source /etc/bashrc
fi

# Making this next line active may break some commands (like scp) due to the
# extra verbosity.
verbose=true

#------------------------------------------------------------------------------#
# CCS-2 standard setup
#-----------------------------------------------------------------------------#

# If this is an interactive shell then the environment variable $- should
# contain an "i":
case ${-} in
*i*)
   export INTERACTIVE=true
   if test -n "${verbose}"; then echo "in ~/.bashrc"; fi
   # If this is an interactive shell and DRACO_ENV_DIR isn't set. Assume that we
   # need to source the .bash_profile.
   if [[ -z "${DRACO_ENV_DIR}" ]] && [[ -f ${HOME}/.bash_profile ]]; then
     if test -n "${verbose}"; then echo "source $HOME/.bash_profile"; fi
     source $HOME/.bash_profile
   fi
   ;;
*) # Not an interactive shell
  export INTERACTIVE=false
  export DRACO_ENV_DIR=$HOME/draco/environment
  ;;
esac

#------------------------------------------------------------------------------#
# Draco developer environment
#------------------------------------------------------------------------------#
if [[ -f ${DRACO_ENV_DIR}/bashrc/.bashrc ]]; then

  source ${DRACO_ENV_DIR}/bashrc/.bashrc

  # --------------- override defaults set by Draco .bashrc ---------------

  # colored GCC warnings and errors
  export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
  # export TERM=xterm-256color

  # shopt options -------------------------------------------------------------#
  # https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html#The-Shopt-Builtin

  #shopt -s checkwinsize # autocorrect window size
  shopt -s cdspell # autocorrect spelling errors on cd command line.
  #shopt -s histappend # append to the history file, don't overwrite it
  #shopt -s direxpand

  #HISTCONTROL=ignoreboth
  #HISTSIZE=1000
  #HISTFILESIZE=2000

  #ulimit -c 0

fi

#------------------------------------------------------------------------------#
# User Customizations
#------------------------------------------------------------------------------#

if test "$INTERACTIVE" = true; then

  # aliases
  source ~/.bash_aliases
  source ~/.bash_functions

  # Set terminal title
  echo -ne "\033]0;${nodename}\007"
  # fancy prompt
  source ~/.bash_prompt
  # special local setup
  if [[ `uname -r` =~ "Microsoft" || `uname -r` =~ "microsoft" ]] ; then
    if [[ -f ~/.bashrc_wls2 ]]; then
      source ~/.bashrc_wls2;
    fi
  fi

  # home, scratchdir, modulefiles
  export CDPATH=.:$HOME
  extra_dirs="/scratch /scratch/$USER"
  for dir in $extra_dirs; do
    if [[ -d $dir ]]; then export CDPATH=$CDPATH:$dir; fi
  done

  if test -n "${verbose}"; then echo "done with $HOME/.bashrc"; fi

fi

#------------------------------------------------------------------------------#
# End ~/.bashrc
#------------------------------------------------------------------------------#
