#!/bin/zsh
dir="$(dirname "$0")"

res=$(echo -e "lock\nsuspend\nrestart\nhalt\nquit\ncancel" \
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
    'suspend')
        physlock & { sleep 3 ; sudo systemctl suspend }
        exit 0
        ;;
    'lock')
        physlock
        exit 0
        ;;
    *)
        echo "wut?"
        ;;
esac
