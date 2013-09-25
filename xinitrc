#!/bin/zsh


echo "xinit started: $*; $1"

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

cdir="$(dirname "$0")"

xrdb -merge ~/.Xresources

case "$1" in
    hl) exec herbstluftwm -c "$( readlink -f "${cdir}/hl_autostart.sh")" ;;
    fluxbox) exec fluxbox ;;
    *) exit 1 ;;
esac

