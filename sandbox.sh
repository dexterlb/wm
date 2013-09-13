#!/bin/zsh
cdir="$(readlink -f "$(dirname "${0}")")"
. "${cdir}/visual.sh"

{
    while true; do
        mpc -h "${mpd_host}" -p "${mpd_port}" idleloop
        echo "player dc" >&3
        sleep 8                 # fail/disconnect retry timeout
    done | while true; do
        head -1 > /dev/null     # wait for event
        echo "player event"
        sleep 0.5               # min time between updates
    done 
} 3>&1 2>/dev/null &
echo $! > pid
