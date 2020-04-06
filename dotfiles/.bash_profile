# .bash_profile
#
# ~/.bash_profile is sourced only for login shells.
#------------------------------------------------------------------------------#
if test -f /etc/bashrc; then
  source /etc/bashrc
fi

if [ "$(umask)" == "0000" ]; then
  umask 0077
fi

# Making this next line active may break some commands (like scp) due to the
# extra verbosity.
verbose=true

#------------------------------------------------------------------------------#
# CCS-2 standard setup
#------------------------------------------------------------------------------#

# If this is an interactive shell then the environment variable $- should
# contain an "i":
case ${-} in
  *i*)
    export INTERACTIVE=true
    if test -n "${verbose}"; then echo "in ~/.bash_profile"; fi
    ;;
  *) # Not an interactive shell
    export INTERACTIVE=false
    ;;
esac

#------------------------------------------------------------------------------#
# Draco Developer Environment
#------------------------------------------------------------------------------#
export DRACO_ENV_DIR=${HOME}/draco/environment
if [[ -f ${DRACO_ENV_DIR}/bashrc/.bashrc ]]; then
  source ${DRACO_ENV_DIR}/bashrc/.bashrc
fi

#------------------------------------------------------------------------------#
# User Customizations
#------------------------------------------------------------------------------#
if [[ "${INTERACTIVE:-false}" = true ]]; then

  umask 077

  export USERNAME=kellyt
  export NAME="Kelly (KT) Thompson"
  export EDITOR="emacs -nw"
  export LPDEST=gumibears
  export COVFILE=${HOME}/test.cov

  # Silence warnings from GTK/Gnome
  export NO_AT_BRIDGE=1
  export LIBGL_ALWAYS_INDIRECT=1
  export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
  export TERM=xterm-256color

  # aliases
  source ~/.bash_aliases
  source ~/.bash_functions

  # Prompt ----------------------------------------------------------------------#
  # - see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/

  if test "$TERM" = emacs || \
      test "$TERM" = dumb  || \
      test -z "`declare -f npwd | grep npwd`"; then
    export PS1="\h:\w [\!] % "
    export LS_COLORS=''
    #    else
    #      found=`declare -f npwd | wc -l`
    #      if test ${found} != 0; then
    #        export PS1="\[\033[34m\]\h:\[\033[32m\]\$(npwd)\[\033[35m\]\$(parse_git_branch)\[\033[00m\] [\!] % "
    #      fi
  fi

  #    if [[ `uname -r` =~ "Microsoft" ]]; then
  #      source ~/.bash_wls
  #    fi

  # SSH keys ----------------------------------------------------------- #
  reloadkeys

  # Modules ------------------------------------------------------------ #
  if test -n "$MODULESHOME"; then
    if test `uname -m` = x86_64; then
      module load htop
    fi
  fi

  # Set terminal title
  # echo -ne "\033]0;${nodename}\007"

  # shopt options -------------------------------------------------------------#
  # https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html#The-Shopt-Builtin

  shopt -s cdspell # attempt to fix mispelled directory names
  case ${nodename} in
    sn*) shopt -s direxpand ;;
  esac

  # LaTeX ---------------------------------------------------------------------- #

  # extradirs="$HOME/imcdoc/sty"
  # for mydir in ${extradirs}; do
  #     if test -z "`echo $TEXINPUTS | grep $mydir`" && test -d $mydir; then
  #         export TEXINPUTS=$mydir:$TEXINPUTS
  #     fi
  # done
  # extradirs="$HOME/imcdoc/bib"
  # for mydir in ${extradirs}; do
  #     if test -z "`echo $BSTINPUTS | grep $mydir`" && test -d $mydir; then
  #         export BSTINPUTS=$mydir:$BSTINPUTS
  #     fi
  # done
  # extradirs="$HOME/imcdoc/bib"
  # for mydir in ${extradirs}; do
  #     if test -z "`echo $BIBINPUTS | grep $mydir`" && test -d $mydir; then
  #         export BIBINPUTS=$mydir:$BIBINPUTS
  #     fi
  # done
  # unset extradirs

  if test -n "${verbose}"; then echo "done with ~/.bash_profile"; fi

fi # if test "$INTERACTIVE" = "true"

# ssh -t ml-fey bash --norc --noprofile

#------------------------------------------------------------------------------#
# end ~/.bash_profile
#------------------------------------------------------------------------------#
