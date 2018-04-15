

case "$-" in
  *i*)
  bind '"\e[A": history-search-backward'
  bind '"\e[B": history-search-forward'
  ;;
esac
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\] \[\033[01;34m\]\w\[\033[01;33m\]$(__git_ps1)\n\[\033[00m\]\$ '

export EDITOR=vim

export PATH=${HOME}/local/bin:${PATH}
