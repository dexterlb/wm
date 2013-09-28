#!/bin/zsh
cdir="$(dirname "${0}")"
monitor=${1:-0}
. "${cdir}/visual.sh"
. "${cdir}/interfaces.sh"

####
# true if we are using the svn version of dzen2
# depending on version/distribution, this seems to have version strings like
# "dzen-" or "dzen-x.x.x-svn"
if dzen2 -v 2>&1 | head -n 1 | grep -q '^dzen-\([^,]*-svn\|\),'; then
    dzen2_svn="true"
else
    dzen2_svn=""
fi

function suicide {
    rm -rf /tmp/panelwatch
    kill ${childpids[@]}
    sleep 1 &
    kill -- -$(ps opgid= "$!")
}

function mpd_trim {
    if [[ -n "${2}" ]]; then
        dclr_reset="${2}"
    else
        dclr_reset="$(dclr)"
    fi
    echo "$1" | perl -pe "s/\^/^^/g; s/(?<=^.{12}).{3,}(?=.{12}$)/$(dclr ${pa_hl2})~${dclr_reset}/g"
}

function join {
    sep=''
    for i in ${@:2}; do
        echo -n "${sep}${i}"
        sep="${1}"
    done
}

function uniq_linebuffered {
    awk -W interactive '$0 != l { print ; l=$0 ; fflush(); }' "$@"
}

function watchloop {
    local spid sstat
    while true; do
        ${@:2}
        sleep ${1} &
        spid=$!
        mkdir -p /tmp/panelwatch
        echo "${spid}" > "/tmp/panelwatch/${@:2}"
        wait "${spid}"
        sstat=$?
        if [[ ${sstat} =~ '^(138|0)$' ]] || break
    done > >(uniq_linebuffered)
}

herbstclient pad $monitor $pa_height
{
    # events:
    childpids=( )

    # notification loop
    {
        "${cdir}/statnot.py" | while read -d$'\0' notif; do
            echo -n "notif"
            if [[ -n "${notif}" ]]; then
                a=( ${(f)notif} )
                title="${a[1]}"
                body="$(join "$(dclr ${pa_hl2}) $ $(dclr)" ${a[@]:1})"
                echo -n " $(dclr ${pa_hl})${title}$(dclr) ${body}"
            fi
            echo
        done
    } 2>/dev/null &
    childpids+=( $! )

    # mpd loop:
    {
        while true; do
            echo "player event"
            mpc -h "${mpd_host}" -p "${mpd_port}" idleloop
            get_mpd dc >&3
            sleep 8 || break        # fail/disconnect retry timeout
        done | while true; do
            head -1 > /dev/null     # wait for event
            get_mpd event
            sleep 0.5 || break      # min time between updates
        done 
    } 3>&1 2>/dev/null &
    childpids+=( $! )

    watchloop 2 get_battery 1 &
    childpids+=( $! )

    watchloop 5 get_binclock &
    childpids+=( $! )

    watchloop 5 get_loadavg &
    childpids+=( $! )

    watchloop 5 get_brightness &
    childpids+=( $! )

    watchloop 3 get_gpu &
    childpids+=( $! )

    herbstclient --idle
    suicide
} 2>/dev/null | {

    TAGS=( $(herbstclient tag_status) )
    visible=true
    loadavg=""
    date=""
    mpd_str=""
    brightness=""
    gpu=""
    notification=""
    windowtitle=""
    bordercolor="#$pa_outl"
    separator="$(dclr ${pa_hl})|$(dclr)"
    while true ; do
        {

            # panel background
            if [[ -n "${notification}" ]]; then
                panelbg="${baked_panelbg_notif}"
            else
                panelbg="${baked_panelbg}"
            fi
            echo -n "^i(${panelbg})^ib(1)^p(-${pa_width})"

            # draw logo
            echo -n "^p(2)^i(${baked_logo}) "
            # draw tags
            for i in "${TAGS[@]}" ; do
                dontprint=0
                case ${i:0:1} in
                    '#')    # viewed on current monitor
                        dclr ${pa_hl}
                        ;;
                    '-')    # viewed on other monitor
                        dclr ${pa_hl2}
                        ;;
                    ':')    # has windows
                        dclr
                        ;;
                    '!')    # urgent
                        dclr ${pa_u}
                        ;;
                    *)
                        dontprint=1
                        ;;
                esac
                if [[ ${dontprint} == 0 ]]; then
                    if [ ! -z "$dzen2_svn" ] ; then
                        echo -n "^ca(1,herbstclient focus_monitor $monitor && "'herbstclient use "'${i:1}'")'"${i:1}$(dclr) ^ca()"
                    else
                        echo -n "${i:1}$(dclr) "
                    fi
                fi
            done
            echo -n "$separator"
        } | read leftmost
        # small adjustments
        if [[ -n "${notification}" ]]; then
            right="${notification} ";
        else
            right="${mpd_str} ${date} ${gpu}${battery} ${brightness} ${loadavg} "
        fi

        rightwidth=$(pawidth "${right}")
        maxtitlewidth=$(( pa_width - $(pawidth ${leftmost}) - rightwidth ))
        # fixme: don't assume text is monospace!
        titletrim=$(( (($(mono_textwidth "${windowtitle}") - maxtitlewidth) / charwidth ) + 7))
        if [[ ${titletrim} -le 0 ]]; then
            titletrim=0;
            titleseparator="";
        else
            titleseparator="$(dclr ${pa_hl})..${separator}"
        fi
        left="${leftmost} $(echo "${windowtitle}" | perl -pe "s/.{${titletrim}}$//; s/\\^/^^/") ${titleseparator}"

        echo -n "${left}^pa($((${pa_width} - ${rightwidth})))${right}"
        echo



        # wait for next event
        read line || break
        cmd=( ${=line} )
        echo "cmd: ${cmd[@]} [${cmd[1]}]" >&2
        # find out event origin
        case "${cmd[1]}" in
            tag*)
                TAGS=( $(herbstclient tag_status $monitor) )
                echo "tags: ${TAGS[@]}" >&2
                ;;
            date)
                date="${cmd[@]:1}"
                echo "date: ${date}" >&2
                ;;
            quit_panel)
                echo "quit" >&2
                suicide
                exit
                ;;
            togglehidepanel)
                currentmonidx=$(herbstclient list_monitors |grep ' \[FOCUS\]$'|cut -d: -f1)
                if [ -n "${cmd[2]}" ] && [ "${cmd[2]}" -ne "$monitor" ] ; then
                    continue
                fi
                if [ "${cmd[2]}" = "current" ] && [ "$currentmonidx" -ne "$monitor" ] ; then
                    continue
                fi
                echo "^togglehide()"
                if $visible ; then
                    visible=false
                    herbstclient pad $monitor 0
                else
                    visible=true
                    herbstclient pad $monitor $pa_height
                fi
                ;;
            reload)
                echo "reload" >&2
                suicide
                exit
                ;;
            focus_changed|window_title_changed)
                windowtitle="${cmd[@]:2}"
                echo "title: ${windowtitle}" >&2
                ;;
            loadavg)
                loadavg="${cmd[@]:1}"
                echo "loadavg: ${loadavg}" >&2
                ;;
            bat)
                battery="${cmd[@]:2}"
                echo "battery: ${battery}" >&2
                ;;
            notif)
                notification="${cmd[@]:1}"
                echo "notif: ${notification}" >&2
                ;;
            brightness)
                brightness="${cmd[@]:1}"
                echo "brightness: ${brightness}" >&2
                ;;
            mpd)
                mpd_str="${cmd[@]:1}"
                echo "mpd: ${mpd_str}" >&2
                ;;
            gpu)
                gpu="${cmd[@]:1}"
                if [[ -n "${gpu}" ]]; then
                    gpu="${gpu} "
                fi
                echo "gpu: ${mpd_str}" >&2
                ;;
        esac
    done
# } 2> /dev/null \
# } \
} 2>/tmp/dzen_msg | tee /tmp/dzen_debug \
    | dzen2 -w $pa_width -x $pa_x -y $pa_y -ta l ${dzen_common[@]}
