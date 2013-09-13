#!/bin/zsh
dir="$(dirname "$0")"

res=$(echo -e "restart\nhalt\nquit\ncancel" \
    | "$dir/dmenu.sh" stdin "manage session")

function killx {
    herbstclient quit
}

case ${res} in
    'restart')
        systemctl reboot & killx
        exit 0
        ;;
    'halt')
        systemctl poweroff & killx
        exit 0
        ;;
    'quit')
        killx
        exit 0
        ;;
    *) ;;
esac
