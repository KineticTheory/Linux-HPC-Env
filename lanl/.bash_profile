# .bash_profile
#
# ~/.bash_profile is sourced only for login shells.
#------------------------------------------------------------------------------#
if test -f /etc/bashrc; then
  source /etc/bashrc
fi

# Making this next line active may break some commands (like scp) due to the
# extra verbosity.
# verbose=true

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

    export USERNAME=kellyt
    export NAME="Kelly (KT) Thompson"
    export EDITOR="emacs -nw"
    export LPDEST=gumibears
    export COVFILE=${HOME}/test.cov

    # aliases, some bash function defs,
    source ~/.bash_interactive

    if [[ `uname -r` =~ "Microsoft" ]]; then
      source ~/.bash_wls
    fi

fi # if test "$INTERACTIVE" = "true"

# ssh -t ml-fey bash --norc --noprofile

#if shopt -q login_shell; then
#  echo "login_shell"
#fi

#------------------------------------------------------------------------------#
# end ~/.bash_profile
#------------------------------------------------------------------------------#
