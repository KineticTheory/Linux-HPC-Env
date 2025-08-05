# .bash_profile
#
# ~/.bash_profile is sourced only for login shells.
# ------------------------------------------------------------------------------------------------ #

#if test -f /etc/bashrc; then
#  source /etc/bashrc
#fi

[[ "$(umask)" == "0000" ]] && umask 0007

# Making this next line active may break some commands (like scp) due to the extra verbosity.
verbose=

# ------------------------------------------------------------------------------------------------ #
# CCS-2 standard setup
# ------------------------------------------------------------------------------------------------ #

# If this is an interactive shell then the environment variable $- should contain an "i":
case ${-} in
  *i*)
    export INTERACTIVE=true
    [[ "${verbose:=false}" == "true" ]] &&  echo "in ~/.bash_profile"
    ;;
  *)
    # Not an interactive shell
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

  #if [[ "$TERM" = emacs ]] || [[ "$TERM" = dumb ]] || [[ -z "`declare -f npwd | grep npwd`" ]];
  #then
  #  export PS1="\h:\w [\!] % "
  #  export LS_COLORS=''
  #elif [[ -f $HOME/.bash_prompt ]]; then
  #  source ~/.bash_prompt
  #fi
  if [[ `uname -r` =~ "Microsoft" || `uname -r` =~ "microsoft" ]] ; then
    if [[ -f ~/.bashrc_wsl2 ]]; then
      source ~/.bashrc_wsl2;
    fi
  fi

  # shopt options -------------------------------------------------------------#
  # https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html#The-Shopt-Builtin

  shopt -s cdspell # attempt to fix misspelled directory names
  case ${nodename} in
    # do not escape env variables when doing tab completion.
    ve* | ro* | darwin* | cn*) shopt -s direxpand ;;
  esac

  # Special setup per platform ------------------------------------------------- #
  case ${nodename} in
    darwin-fe*)
      add_to_path /projects/draco/vendors/bin PATH
      GOPATH=/projects/draco/vendors
      function _update_ps1() {
        # see options by running 'powerline-go -h'
        # https://github.com/justjanne/powerline-go
        # theme opts: {default, low-contrast, gruvbox, solarized-dark16, solarized-light16}
        # might need '-mode compatible
        PS1="$($GOPATH/bin/powerline-go -theme default -error $?)"
      }
      if [ "$TERM" != "linux" ] && [ -f "$GOPATH/bin/powerline-go" ]; then
        PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
      fi
     ;;
  esac

  [[ -d $HOME/.local/bin ]] && export PATH+=":$HOME/.local/bin"

  if test -n "${verbose}"; then echo "in ~/.bash_profile ... done"; fi
fi # if test "$INTERACTIVE" = "true"

# Added by LM Studio CLI (lms)
if [[ -d /home/kellyt/.lmstudio/bin ]]; then
  export PATH="$PATH:/home/kellyt/.lmstudio/bin"
fi

# ------------------------------------------------------------------------------------------------ #
# end ~/.bash_profile
# ------------------------------------------------------------------------------------------------ #
