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

function uniq_linebuffered {
    awk -W interactive '$0 != l { print ; l=$0 ; fflush(); }' "$@"
}

function suicide {
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
            echo "player dc" >&3
            sleep 8 || break        # fail/disconnect retry timeout
        done | while true; do
            head -1 > /dev/null     # wait for event
            echo "player event"
            sleep 0.5 || break      # min time between updates
        done 
    } 3>&1 2>/dev/null &
    childpids+=( $! )

    # battery loop:
    while true ; do
        get_battery 1
        sleep 1 || break
    done > >(uniq_linebuffered)  &
    childpids+=( $! )

    # clock loop:
    while true ; do
        get_binclock
        sleep 1 || break
    done > >(uniq_linebuffered)  &
    childpids+=( $! )

    # loadavg loop:
    while true ; do
        get_loadavg
        sleep 5 || break
    done > >(uniq_linebuffered)  &
    childpids+=( $! )

    herbstclient --idle
    kill ${childpids[@]}
    suicide
} 2>/dev/null | {

    TAGS=( $(herbstclient tag_status) )
    visible=true
    loadavg=""
    date=""
    notification=""
    m_status='dc'
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
            right="${m_str} ${date} ${battery} ${loadavg} "
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
            player)
                case "${cmd[2]}" in
                    dc)
                        echo "player dc" >&2
                        m_status='dc'
                        ;;
                    event)
                        hr="$(mpc -h "$mpd_host" -p "$mpd_port" | tail -2)"
                        if [[ $? != 0 ]]; then
                            m_status='dc'
                        else
                            echo "$hr" | head -1 | perl -ne 'if ($_ =~ /(^\[)([^\]]+)(\].*)/) {print "$2\n"} else {print "stopped\n"}' \
                                | read m_status
                            echo "$hr" | tail -1 | perl -ne 'if ($_ =~ /(^volume\:\s*)([0-9]+)(\%.*)/) {print "$2\n"} else {print "0\n"}' \
                                | read m_volume
                            # echo "$hr" | head -1 | perl -ne 'if ($_ =~ /(.+)([0-9]+\:[0-9]+)(\/)([0-9]+\:[0-9]+)/) {print "$2\n$4\n"} else {print "0\n0\n"}' \
                            #     | {read m_time_now; read m_time_total}
                            mpc -h "${mpd_host}" -p "${mpd_port}" -f '%artist%\n%album%\n%title%' current \
                                | {read m_artist ; read m_album ; read m_title}

                            if [[ ${m_status} == "stopped" ]]; then
                                m_str="DON'T PANIC!"
                            elif [[ ${m_status} == "dc" ]]; then
                                m_str="PANIC!"
                            elif [[ ${m_status} =~ "(playing|paused)" ]]; then
                                #staticon="^i(${bakeddir}/m_${m_status}.xpm)"
                                if [[ ${m_status} == "playing" ]]; then
                                    statclr="$(dclr ${pa_hl})"
                                else
                                    statclr="$(dclr)"
                                fi
                                volume="$(echo "${m_volume}" | gdbar -s -o -w 40 -h 10 -nonl -bg "#${pa_inactive[1]}" -fg "#${pa_active[1]}")"
                                m_str="$(dclr ${pa_hl})${staticon}$(dclr) $(mpd_trim "${m_artist}") - ${statclr}$(mpd_trim ${m_title} "${statclr}")$(dclr) ${volume}"
                                #m_str="${staticon} $(mpd_trim "${m_artist}") - $(dclr ${pa_hl})$(mpd_trim ${m_title} "$(dclr ${pa_hl})")$(dclr) ${volume}"
                            else
                                m_str="fixme..."
                            fi

                        fi
                        echo "player event: $m_str" >&2
                        ;;
                esac
                ;;
        esac
    done
# } 2> /dev/null \
# } \
} 2>/tmp/dzen_msg | tee /tmp/dzen_debug \
    | dzen2 -w $pa_width -x $pa_x -y $pa_y -ta l ${dzen_common[@]}
