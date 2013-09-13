#!/bin/zsh
dir="$(dirname "$0")"
mode=$(echo -e "auto\nnever\nalways" | "$dir/dmenu.sh" stdin "boinc mode")
if [[ -n "${mode}" ]]; then
    boinccmd --set_run_mode "${mode}"
fi
