# .bashrc_aliases
#
# .bashrc_aliases is sourced by interactive shells from
# .bash_profile and .bashrc
#------------------------------------------------------------------------------#

# pragma once
if [[ `alias bash_aliases_pragma_once 2>&1 | grep -c "bash: alias"` != 0 ]]; then
  alias bash_aliases_pragma_once='ls'
  [[ "${verbose:=false}" == "true" ]] && echo "in ~/.bash_aliases"

  #------------------------------------------------------------------------------#
  # User Customizations
  #------------------------------------------------------------------------------#

  ncpus=`lscpu | grep CPU\(s\) | head -n 1 | awk '{ print $2 }'`

  alias ack='ack --ignore-dir=install --ignore-dir=build'
  if [[ -d /usr/projects/jayenne/devs/kellyt/build ]]; then
    alias cdbuild='cd /usr/projects/jayenne/devs/kellyt/build'
  fi
  alias cmakebc='cmake -DGCC_ENABLE_GLIBCXX_DEBUG=ON'
  alias cmakecov='cmake -DCODE_COVERAGE=ON'
  alias cmakect='C_FLAGS=-Werror CXX_FLAGS=-Werror cmake -Wdeprecated -Wdev -DDRACO_STATIC_ANALYZER=clang-tidy'
  alias cmakedebug='CUDA_FLAGS=-Werror\ all-warnings C_FLAGS=-Werror CXX_FLAGS=-Werror cmake -Wdeprecated -Wdev'
  alias cmakedebugfast='cmake -DBUILD_TESTING=OFF'
  alias cmakerel='cmake -GNinja -DCMAKE_BUILD_TYPE=RELEASE'
  alias cmakerelfast='cmake -DCMAKE_BUILD_TYPE=RELEASE -DBUILD_TESTING=OFF'
  alias debug='totalview $* 2>/dev/null'
  alias debuga1='mpirun -n 1 totalview /path/to/exe -a <args_for_exe> : -n 127' # $1=<exe> $*=<args>
  alias ehco='echo'
  alias pcmake='cmake-Wdeprecated -Wdev --warn-uninitialized --warn-unused-vars'
  alias emacs='emacs -g 110x70' #  -fn Inconsolata &> $HOME/emacs.log
  alias gitk='gitk --all'
  alias gittrigger='git commit --allow-empty -m "trigger pipeline" && git push'
  alias gitup='git fetch --all --prune; remote=`[[ $(git remote -v | grep -c upstream) ]] || echo "upstream" && echo "origin"`; git merge ${remote}/$(git rev-parse --abbrev-ref HEAD)'
  alias moduel='module'
  alias mpiruntv='mpirun -tv $* 2>/dev/null'
  alias qtcreator='qtcreator -noload Welcome'
  alias rtt='resettermtitle'
  alias vdir='pushd $VENDOR_DIR'
  alias wget='wget --user-agent=Mozilla --content-disposition -E -c'
  alias xload='xload -fg brown -fn 6x13 -geometry 180x100+1500+0'

  case $nodename in
    ve-rfe*)
      alias git='git --no-pager'
      ;;
  esac

  #if [[ -f ~/.ssh/xfkeytab ]]; then
  #  alias kerbp='kinit -f -l 8h -kt ~/.ssh/xfkeytab kellytpush@lanl.gov'
  #fi
  #if [[ -f ~/.ssh/cron.keytab ]]; then
  #  alias kerb='kinit -f -l 8h -kt ~/.ssh/cron.keytab kellyt@lanl.gov'
  #fi

  # Kerberos
  alias kerb='kinit -f -l 8h -kt ~/.ssh/kellyt-hpcalias.keytab kellyt-hpcalias@HPC.LANL.GOV'

  [[ "${verbose:=false}" == "true" ]] && echo "in ~/.bash_aliases ... done"

fi

#------------------------------------------------------------------------------#
# End .bash_aliases
#------------------------------------------------------------------------------#
