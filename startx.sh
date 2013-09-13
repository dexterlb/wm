# load from your bash or zsh profile


function xs {
    TTY=$(tty)
    TTY=${TTY#/dev/}
    vt=$(printf 'vt%02d' "${TTY#tty}")

    if [ -z ${xinitrc} ]; then
        xinitrc="$HOME/.xinitrc"
    fi

    echo "starting X with parameter $1"
    startx "$xinitrc" "$1" -- "$vt" &> /tmp/x_out

    clear
    echo "X has exited. Output has been saved to /tmp/x_out."
    echo "Press enter to relog."
    read enter
    exit
}

function xinteractive {
    echo -en "\n"

    if [[ -z "$1" ]]; then
        echo -n "Enter choice (hl: 1, xmonad: 2, restart: r, halt: h, console: c): "
        read c
    else
        c="$1"
    fi

    echo -en "\n"

    case $c[1] in 
        1) xs hl ;;
        2) xs xmonad ;;
        
        r) systemctl reboot ;;
        h) systemctl poweroff ;;
        c) return ;;
        
        *) exit ;;
    esac

}

# start X if we're on tty1
function xauto {
    if [[ -n ${1} ]]; then
        export xinitrc=${1}
    fi
    if [[ -z $DISPLAY ]] && [[ $(tty) =~ "/dev/tty[1-9]" ]]; then
        if [[ $(tty) = "/dev/tty1" ]] && [[ ! -f ~/x_noauto ]]; then
            xinteractive 1
        else
            xinteractive
        fi
    fi
}


 
