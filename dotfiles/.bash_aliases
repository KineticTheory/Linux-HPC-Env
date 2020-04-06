# .bashrc_aliases
#
# .bashrc_aliases is sourced by interactive shells from
# .bash_profile and .bashrc
#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
# User Customizations
#------------------------------------------------------------------------------#

if test -n "${verbose}"; then echo "in ~/.bash_aliases"; fi

alias ack='ack --color-lineno="bold blue"'
alias pcmake='cmake-Wdeprecated -Wdev --warn-uninitialized --warn-unused-vars'
alias cmakedebug='C_FLAGS=-Werror CXX_FLAGS=-Werror cmake -Wdeprecated -Wdev'
alias cmakect='C_FLAGS=-Werror CXX_FLAGS=-Werror cmake -Wdeprecated -Wdev -DDRACO_STATIC_ANALYZER=clang-tidy'
# alias cmakebc='cmake -DGCC_ENABLE_GLIBCXX_DEBUG=ON'
alias cmakedebugfast='cmake -DBUILD_TESTING=OFF'
alias cmakerel='cmake -DCMAKE_BUILD_TYPE=RELEASE'
alias cmakerelfast='cmake -DCMAKE_BUILD_TYPE=RELEASE -DBUILD_TESTING=OFF'
ncpus=`lscpu | grep CPU\(s\) | head -n 1 | awk '{ print $2 }'`
alias ctest='ctest --test-load ${ncpus:-1}'
alias debug='totalview $* 2>/dev/null'
alias eclipse='eclipse -data /var/tmp/kgt/workspace -nosplash'
alias ehco='echo'
alias em='emacsclient -c --alternate-editor=emacs'
if test -x /bin/emacs; then
  alias emacs='/bin/emacs -fn Inconsolata &> $HOME/emacs.log'
fi
#alias emacs='/bin/emacs -fn 6x13 &> /dev/null'
alias gitk='gitk --all'
alias gitfetch='git fetch --all --prune --tags'
alias gitup='git fetch --all --prune; git merge upstream/develop'
alias gt='gnome-terminal'
alias moduel='module'
alias mpiruntv='mpirun -tv $* 2>/dev/null'
alias qtcreator='qtcreator -noload Welcome'
alias rtt='resettermtitle'
alias rzansel='ssh -t ihpc-gate1.lanl.gov ssh rzansel.llnl.gov'
alias vdir='pushd $VENDOR_DIR'
alias vi='emacs -nw'
alias vulcan='ssh -t ihpc-gate1.lanl.gov ssh vulcan.llnl.gov'
alias wget='wget --user-agent=Mozilla --content-disposition -E -c'
alias xload='xload -fg brown -fn 6x13 -geometry 180x100+1500+0'
if [[ `which okular 2> /dev/null | wc -l` == 1 ]]; then
  alias xpdf='okular'
else
  alias xpdf='evince'
  # atril
fi

if [[ -f ~/.ssh/xfkeytab ]]; then
  alias kerbp='kinit -f -l 8h -kt ~/.ssh/xfkeytab kellytpush@lanl.gov'
fi
if [[ -f ~/.ssh/cron.keytab ]]; then
  alias kerb='kinit -f -l 8h -kt ~/.ssh/cron.keytab kellyt@lanl.gov'
fi

# Kerberos
alias kerb='kinit -f -l 8h -kt ~/.ssh/cron.keytab kellyt@lanl.gov'

if test -n "${verbose}"; then echo "done with ~/.bash_aliases"; fi

#------------------------------------------------------------------------------#
# End .bash_aliases
#------------------------------------------------------------------------------#
