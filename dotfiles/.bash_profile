# .bash_profile
#
# ~/.bash_profile is sourced only for login shells.
# ------------------------------------------------------------------------------------------------ #

#if test -f /etc/bashrc; then
#  source /etc/bashrc
#fi

[[ "$(umask)" == "0000" ]] && umask 0007

# Making this next line active may break some commands (like scp) due to the extra verbosity.
verbose=true

# ------------------------------------------------------------------------------------------------ #
# CCS-2 standard setup
# ------------------------------------------------------------------------------------------------ #

# If this is an interactive shell then the environment variable $- should contain an "i":
case ${-} in
  *i*)
    export INTERACTIVE=true
    if test -n "${verbose}"; then echo "in ~/.bash_profile"; fi
    ;;
  *) # Not an interactive shell
    export INTERACTIVE=false
    if test -n "${verbose}"; then echo "in ~/.bash_profile (NI)"; fi
    ;;
esac

# ------------------------------------------------------------------------------------------------ #
# Draco Developer Environment
# ------------------------------------------------------------------------------------------------ #
export DRACO_ENV_DIR=${HOME}/draco/environment
if [[ -f ${DRACO_ENV_DIR}/bashrc/.bashrc ]]; then
  source ${DRACO_ENV_DIR}/bashrc/.bashrc
fi

if [[ -d /usr/projects/jayenne/devs/kellyt/lap/flag ]]; then
  export OPUS=/usr/projects/jayenne/devs/kellyt/lap/flag
  export SUITE=CTS1Ifast
fi

# ------------------------------------------------------------------------------------------------ #
# User Customizations
# ------------------------------------------------------------------------------------------------ #
if [[ "${INTERACTIVE:-false}" = true ]]; then

  umask 0007

  export USERNAME=kellyt
  export NAME="Kelly (KT) Thompson"
  export EDITOR="emacs -nw"
  export LPDEST=gumibears

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

  if [[ "$TERM" = emacs ]] || [[ "$TERM" = dumb ]] || [[ -z "`declare -f npwd | grep npwd`" ]];
  then
    export PS1="\h:\w [\!] % "
    export LS_COLORS=''
  elif [[ -f $HOME/.bash_prompt ]]; then
    source ~/.bash_prompt
  fi
  if [[ `uname -r` =~ "Microsoft" || `uname -r` =~ "microsoft" ]] ; then
    if [[ -f ~/.bashrc_wsl2 ]]; then
      source ~/.bashrc_wsl2;
    fi
  fi

  # SSH keys ----------------------------------------------------------- #
  case $target in
    nid* | cn*  ) ;;
    *) [[ -z $SLURM_NODELIST ]] && reloadkeys ;;
  esac

  # Set terminal title
  # echo -ne "\033]0;${nodename}\007"

  # shopt options -------------------------------------------------------------#
  # https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html#The-Shopt-Builtin

  shopt -s cdspell # attempt to fix mispelled directory names
  case ${nodename} in
    # do not escape env variables when doing tab completion.
    sn* | darwin* | cn*) shopt -s direxpand ;;
  esac

  # LaTeX -------------------------------------------------------------------- #

  # extradirs="$HOME/imcdoc/sty"
  extradirs="$HOME/dracodoc/latex"
  for mydir in ${extradirs}; do
    if test -z "`echo $TEXINPUTS | grep $mydir`" && test -d $mydir; then
      export TEXINPUTS=$mydir:$TEXINPUTS
    fi
  done
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

  # Special setup per platform ------------------------------------------------- #
  case ${nodename} in
    darwin* | cn*)
      # todo: move this into ~/privatemodules
      export SPACK_ROOT=/projects/draco/vendors/spack.20181002
      export PATH=$SPACK_ROOT/bin:$PATH
      ;;
    tt-fey* | tt-login*)
      ulimit -Sc unlimited
      ;;
    ba-fe* | cy-fe* | fi-fe* | ic-fe* | sn-fe*)
      ulimit -Sc unlimited
      ;;
  esac

  if test -n "${verbose}"; then echo "in ~/.bash_profile ... done"; fi
fi # if test "$INTERACTIVE" = "true"

# ------------------------------------------------------------------------------------------------ #
# end ~/.bash_profile
# ------------------------------------------------------------------------------------------------ #
