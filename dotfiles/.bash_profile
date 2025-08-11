# .bash_profile
#
# ~/.bash_profile is sourced only for login shells.
# ------------------------------------------------------------------------------------------------ #

[[ "$(umask)" == "0000" ]] && umask 0007

# Making this next line active may break some commands (like scp) due to the extra verbosity.
# verbose=

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

  export USERNAME=kellyt
  export NAME="Kelly (KT) Thompson"

  # Silence warnings from GTK/Gnome
  export NO_AT_BRIDGE=1
  export LIBGL_ALWAYS_INDIRECT=1
  export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
  export TERM=xterm-256color

  # aliases
  source ~/.bash_aliases
  source ~/.bash_functions

  # shopt options -------------------------------------------------------------#
  # https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html#The-Shopt-Builtin

  shopt -s cdspell # attempt to fix misspelled directory names
  case ${nodename} in
    # do not escape env variables when doing tab completion.
    ve* | ro* | darwin* | cn*) shopt -s direxpand ;;
  esac

  # Added by LM Studio CLI (lms)
  if [[ -d /home/kellyt/.lmstudio/bin ]]; then
    export PATH="$PATH:/home/kellyt/.lmstudio/bin"
  fi

  # Prompt ----------------------------------------------------------------------#
  #if [[ -f $HOME/.bash_prompt ]]; then source ~/.bash_prompt; fi
  if [[ `uname -r` =~ "Microsoft" || `uname -r` =~ "microsoft" ]] ; then
    if [[ -f ~/.bashrc_wsl2 ]]; then
      source ~/.bashrc_wsl2;
    fi
  fi

  # Oh-my-posh Prompt
  if [[ -x ${HOME}/bin/oh-my-posh ]]; then
    #  cd $HOME && curl -s https://ohmyposh.dev/install.sh | bash -s
    export PATH="${HOME}/bin:$PATH"
    export OHMYPOSH_THEME_DIR="${HOME}/.cache/oh-my-posh/themes"
    eval "$(oh-my-posh init bash --config ${OHMYPOSH_THEME_DIR}/marcduiker.omp.json)"
  else
    echo "==> consider installing oh-my-posh for fancy prompt management."
    echo "    cd $HOME && curl -s https://ohmyposh.dev/install.sh | bash -s"
    echo "==> exit and log back in."
    # Alternately, do this on darwin then
    # cd $HOME && scp bin/oh-my-posh ro-rfe:bin/. && scp -r .cache/oh-my-posh ro-rfe:.cache/.
  fi 

  [[ -n "${verbose}" ]] && echo "in ~/.bash_profile ... done"
fi # if test "$INTERACTIVE" = "true"

# ------------------------------------------------------------------------------------------------ #
# end ~/.bash_profile
# ------------------------------------------------------------------------------------------------ #
