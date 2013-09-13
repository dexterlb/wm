#!/bin/zsh
cdir="$(dirname "$0")"

. "${cdir}/visual.sh"

case "$1" in
    stdin)  cmd=dmenu ;;
    run)    cmd=dmenu_run ;;
    *)      echo "supply either 'run' or 'stdin' as first argument" ;;
esac

if [[ -n "${cmd}" ]]; then
    "${cmd}" -f -fn "$xft" -nb "#${pa_default[2]}" -nf "#${pa_default[1]}" \
        -sb "#${pa_default[2]}" -sf "#${pa_hl[1]}" -h "$pa_height" -p "$2"
fi
