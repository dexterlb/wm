#!/bin/zsh
cdir="$(readlink -f "$(dirname "${0}")")"
. "${cdir}/visual.sh"
. "${cdir}/interfaces.sh"

# this is a simple config for herbstluftwm

function hc {
    herbstclient ${@}
}

function ha() {
    cmd_chain+=( ' ~|. ' ${@} )
}

function flush() {
    herbstclient chain ${cmd_chain[@]}
    cmd_chain=( )
}
cmd_chain=( )

# set wallpaper before the WM has got all the settings
feh --bg-fill "${baked_wallpaper}"


ha emit_hook reload

# remove all existing keybindings
ha keyunbind --all

# keybindings
Mod=Mod4
ha keybind $Mod-Shift-q quit
ha keybind $Mod-q reload
ha keybind $Mod-c close

ha keybind $Mod-Return  spawn lilyterm
ha keybind $Mod-p       spawn "${cdir}/dmenu.sh" run
ha keybind $Mod-Escape  spawn "${cdir}/session_menu.sh"
ha keybind $Mod-b       spawn "${cdir}/boinc_menu.sh"
ha keybind $Mod-Shift-p spawn gmrun
ha keybind $Mod-v       spawn pavucontrol
ha keybind $Mod-Shift-b spawn firefox
ha keybind $Mod-Shift-t spawn ts
ha keybind $Mod-Shift-i spawn hexchat

ha keybind Print        spawn zsh -c 'sleep 0.4; scrot -d 0.1 /tmp/s$(date -u +%s).png' 
ha keybind Shift-Print  spawn zsh -c 'sleep 0.4; scrot -d 0.1 -s /tmp/s$(date -u +%s).png' 



# tags
TAG_NAMES=( {1..9} )
TAG_KEYS=( {1..9} 0 )

ha rename default "${TAG_NAMES[1]}" || true
for i in ${TAG_NAMES[@]} ; do
    ha add "${TAG_NAMES[$i]}"
    key="${TAG_KEYS[$i]}"
    if ! [ -z "$key" ] ; then
        ha keybind "$Mod-$key" use_index "$((i - 1))"
        ha keybind "$Mod-Shift-$key" move_index "$((i - 1))"
    fi  # array indices in zsh start from 1. wat.
done


# cycle through tags
ha keybind $Mod-period use_index +1 --skip-visible
ha keybind $Mod-comma  use_index -1 --skip-visible
ha keybind $Mod-Right use_index +1 --skip-visible
ha keybind $Mod-Left  use_index -1 --skip-visible

# layouting
ha keybind $Mod-r remove
ha keybind $Mod-space cycle_layout 1
ha keybind $Mod-u split vertical 0.5
ha keybind $Mod-o split horizontal 0.5
ha keybind $Mod-s floating toggle
ha keybind $Mod-f fullscreen toggle
ha keybind $Mod-t pseudotile toggle

Mpd=$Mod-Ctrl
mpdbinds=(
    "Pause toggle"
    "$Mpd-p toggle"
    "$Mpd-Up volume +3"
    "$Mpd-Down volume -3"
    "$Mpd-Left prev"
    "$Mpd-Right next"
    "$Mpd-period seek 0%"
    "$Mpd-Escape stop"
)
for bind in ${mpdbinds[@]}; do
    sub=( ${=bind} )
    ha keybind "${sub[1]}" spawn \
        mpc -h "${mpd_host}" -p "${mpd_port}" -q ${sub[@]:1}
done

# resizing
RESIZESTEP=0.05
ha keybind $Mod-Alt-h resize left +$RESIZESTEP
ha keybind $Mod-Alt-j resize down +$RESIZESTEP
ha keybind $Mod-Alt-k resize up +$RESIZESTEP
ha keybind $Mod-Alt-l resize right +$RESIZESTEP

# mouse
ha mouseunbind --all
ha mousebind $Mod-Button1 move
ha mousebind $Mod-Button2 resize
ha mousebind $Mod-Button3 zoom

# focus
ha keybind $Mod-BackSpace   cycle_monitor
ha keybind $Mod-Tab         cycle_all +1
ha keybind $Mod-Shift-Tab   cycle_all -1
# ha keybind $Mod-c cycle
ha keybind $Mod-h focus left
ha keybind $Mod-j focus down
ha keybind $Mod-k focus up
ha keybind $Mod-l focus right
ha keybind $Mod-i jumpto urgent
ha keybind $Mod-Shift-h shift left
ha keybind $Mod-Shift-j shift down
ha keybind $Mod-Shift-k shift up
ha keybind $Mod-Shift-l shift right

# colors
ha set frame_border_active_color '#222222'
ha set frame_border_normal_color '#101010'
ha set frame_bg_normal_color '#565656'
ha set frame_bg_active_color '#345F0C'
ha set frame_bg_transparent 1
ha set frame_border_width 1
ha set window_border_width 3
ha set window_border_inner_width 1
ha set window_border_normal_color "#$col_inactive"
ha set window_border_active_color "#$col_hl"
ha set always_show_frame 1
ha set frame_gap 0
# vertical split
hc set default_frame_layout 1
# add overlapping window borders
ha set window_gap -2
ha set frame_padding 2
ha set smart_window_surroundings 0
ha set smart_frame_surroundings 1
ha set mouse_recenter_gap 0

# rules
ha unrule -F
#ha rule class=XTerm tag=3 # move all xterms to tag 3
ha rule focus=on # normally do not focus new clients
# give focus to most common terminals
ha rule class~'(.*[Rr]xvt.*|.*[Tt]erm|Konsole)' focus=on
ha rule windowtype~'_NET_WM_WINDOW_TYPE_(DIALOG|UTILITY|SPLASH)' pseudotile=on
ha rule windowtype='_NET_WM_WINDOW_TYPE_DIALOG' focus=on
ha rule windowtype~'_NET_WM_WINDOW_TYPE_(NOTIFICATION|DOCK)' manage=off

ha rule class~'([Vv]lc|[Mm]player)' tag=9
ha rule class~'(Firefox|[Cc]hromium|[Cc]hrome)' tag=2
ha rule instance~'dwb' tag=2
ha rule instance~'(hon-x86|hon-x86_64|explorer\.exe)' tag=6
ha rule instance~'(xchat|hexchat)' tag=3
ha rule instance~'ts3client_linux_(x86|amd64)' tag=4


herbstclient set tree_style '╾│ ├└╼─┐'

# unlock, just to be sure
ha unlock


# do multi monitor setup here, e.g.:
# ha set_monitors 1280x1024+0+0 1280x1024+1280+0
# or simply:
hc detect_monitors

flush &

{
    # X settings
    xsetroot -cursor_name left_ptr
    export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
    unclutter &             # autohide pointer
    xset b off              # speakerectomy
    xset s off              # no screensaver
    xset s noblank          # no screen blanking
    xset m 3/1 0            # mouse acceleration and speed
    xset -dpms; xset s off  # no screen blanking
    xhost local:boinc       # allow boinc user to use GPU

    "${cdir}/klayout.sh"    # keyboard layout settings
} &

parcellite -n &>/dev/null &         # clipboard manager

# find the panel
panel="${cdir}/panel.sh"
# [ -x "$panel" ] || panel=/etc/xdg/herbstluftwm/panel.sh
# for monitor in $(herbstclient list_monitors | cut -d: -f1) ; do
#     # start it on each monitor
#     $panel $monitor &
# done

# start panel on monitor 0
${panel} 0 &
