# .bashrc_aliases
#
# .bashrc_aliases is sourced by interactive shells from
# .bash_profile and .bashrc
#------------------------------------------------------------------------------#

# pragma once
if [[ `alias bash_aliases_pragma_once 2>&1 | grep -c "bash: alias"` != 0 ]]; then
  alias bash_aliases_pragma_once='ls'
  if test -n "${verbose}"; then echo "in ~/.bash_aliases"; fi

  #------------------------------------------------------------------------------#
  # User Customizations
  #------------------------------------------------------------------------------#

  ncpus=`lscpu | grep CPU\(s\) | head -n 1 | awk '{ print $2 }'`

  # alias ack='ack --color-lineno="bold blue"'
  alias cmakebc='cmake -DGCC_ENABLE_GLIBCXX_DEBUG=ON'
  alias cmakecov='cmake -DCODE_COVERAGE=ON'
  alias cmakect='C_FLAGS=-Werror CXX_FLAGS=-Werror cmake -Wdeprecated -Wdev -DDRACO_STATIC_ANALYZER=clang-tidy'
  alias cmakedebug='C_FLAGS=-Werror CXX_FLAGS=-Werror cmake -Wdeprecated -Wdev'
  alias cmakedebugfast='cmake -DBUILD_TESTING=OFF'
  alias cmakerel='cmake -DCMAKE_BUILD_TYPE=RELEASE'
  alias cmakerelfast='cmake -DCMAKE_BUILD_TYPE=RELEASE -DBUILD_TESTING=OFF'
  # alias ctest='ctest --test-load ${ncpus:-1}'
  alias debug='totalview $* 2>/dev/null'
  alias eclipse='eclipse -data /var/tmp/kgt/workspace -nosplash'
  alias ehco='echo'
  alias em='emacsclient -c --alternate-editor=emacs'
  alias pcmake='cmake-Wdeprecated -Wdev --warn-uninitialized --warn-unused-vars'
  #if test -x /bin/emacs; then
  alias emacs='emacs -g 110x70 -fn Inconsolata &> $HOME/emacs.log'
  #fi
  #alias emacs='/bin/emacs -fn 6x13 &> /dev/null'
  alias gitfetch='git fetch --all --prune --tags'
  alias gitk='gitk --all'
  alias gitup='git fetch --all --prune; git merge upstream/develop'
  alias gt='gnome-terminal'
  alias moduel='module'
  alias mpiruntv='mpirun -tv $* 2>/dev/null'
  alias qtcreator='qtcreator -noload Welcome'
  alias rtt='resettermtitle'
  alias rzansel='ssh -t ihpc-gate1.lanl.gov ssh rzansel.llnl.gov'
  alias sshclean='function _sshclean(){ssh -t $1 bash --noprofile --norc};_sshclean'
  alias vdir='pushd $VENDOR_DIR'
  alias vi='emacs -nw'
  alias wget='wget --user-agent=Mozilla --content-disposition -E -c'
  alias xload='xload -fg brown -fn 6x13 -geometry 180x100+1500+0'
  if [[ `which okular 2> /dev/null | wc -l` == 1 ]]; then
    alias xpdf='okular'
  else
    alias xpdf='evince'
    # atril
  fi

  case $nodename in
    tt-fey* | tt-login*)
      # alias emacs='emacs -fn Inconsolata-9'
      alias git='git --no-pager'
      ;;
  esac

  if [[ -f ~/.ssh/xfkeytab ]]; then
    alias kerbp='kinit -f -l 8h -kt ~/.ssh/xfkeytab kellytpush@lanl.gov'
  fi
  if [[ -f ~/.ssh/cron.keytab ]]; then
    alias kerb='kinit -f -l 8h -kt ~/.ssh/cron.keytab kellyt@lanl.gov'
  fi

  # Kerberos
  alias kerb='kinit -f -l 8h -kt ~/.ssh/cron.keytab kellyt@lanl.gov'

  if test -n "${verbose}"; then echo "in ~/.bash_aliases ... done"; fi
fi

#------------------------------------------------------------------------------#
# End .bash_aliases
#------------------------------------------------------------------------------#
