# .bashrc_functions
#
# .bashrc_functions is sourced by interactive shells from
# .bash_profile and .bashrc
#------------------------------------------------------------------------------#

if test -n "${verbose}"; then echo "source $HOME/.bash_functions"; fi

#------------------------------------------------------------------------------#
# User Customizations
#------------------------------------------------------------------------------#

# Functions ----------------------------------------------------------------#
function eapde ()
{
  export EAP_INHIBIT_KSM=1
  export L_EAP_ENV=new
  source /usr/projects/eap/dotfiles/.bashrc
  module unload paraview
  module list
}

# Convert dos2unix ---------------------------------------------------------#
# https://kb.iu.edu/d/acux
# dos2unix
#   awk '{ sub("\r$", ""); print }' winfile.txt > unixfile.txt
# unix2dos
#   awk 'sub("$", "\r")' unixfile.txt > winfile.txt

function dos2unix ()
{
  dosfile=$1
  unixfile=$dosfile
  tmp=`mktemp`
  awk '{ sub("\r$", ""); print }' $dosfile > $tmp
  cp $tmp $unixfile
}

function unix2dos ()
{
  unixfile=$1
  dosfile=$unixfile
  tmp=`mktemp`
  awk 'sub("$", "\r")' $unixfile > $tmp
  cp $tmp $dosfile
}

function = ()
{
  calc="${@//p/+}";
  calc="${calc//x/*}";
  bc -l <<< "scale=10;$calc"
}

function keychain()
{
  /scratch/vendors/keychain-2.8.5/keychain ~/.ssh/id_rsa
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

#------------------------------------------------------------------------------#
# End .bash_functions
#------------------------------------------------------------------------------#
