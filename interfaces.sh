#!/bin/zsh

function get_binclock {
    echo -n "date "
    "${cdir}/binclock.pl" \
        "^p(2){}^r(10x10)$(dclr)^p(2)" \
        "$(dclr ${pa_inactive})" "$(dclr ${pa_active})" \
        "%4-%3'%5 %2:%1"
    echo
}

function get_loadavg {
    local load b_{state,{active,err}_jobs} cload
    load=$(cat /proc/loadavg | perl -pe 's/\s.+//g')
    b_state=$(boinccmd --get_cc_status | head -5 | perl -ne 'if (m/^\s+not suspended$/) {print "0\n"} elsif (m/^\s+suspended\: user request$/) {print "1\n"} elsif (m/^\s+suspended/) {print "2\n"}')
    if [[ -n "${b_state}" ]]; then
        b_active_jobs=$(boinccmd --get_tasks | perl -ne 'print if /^\s+active_task_state\: 1$/' | wc -l)
        b_err_jobs=$(boinccmd --get_tasks | perl -ne 'print if /^\s+active_task_state\: [2-9][0-9]*$/' | wc -l)
        case ${b_state} in
            0) cload="$(dclr ${pa_hl2})${load}$(dclr)" ;;
            1) cload="$(dclr)${load}" ;;
            2) cload="$(dclr ${pa_hl})${load}$(dclr)" ;;
        esac
        if [[ ${b_active_jobs} -ne 0 ]]; then
            cload="${cload} $(dclr ${pa_hl2})(${b_active_jobs})$(dclr)"
        fi
        if [[ ${b_err_jobs} -ne 0 ]]; then
            cload="${cload} $(dclr ${pa_u})[$b_err_jobs]$(dclr)"
        fi
    else
        cload="$(dclr)${load}"
    fi
    echo "loadavg ${cload}"
}

function touch_state {
    synclient -l | grep TouchpadOff | cut -c31-32
}

function touch_set {
    synclient TouchpadOff="${1}"
}

function touch_toggle {
    touch_set $(( ! $(touch_state) ))
}

function brightness {
    local br
    br="/sys/class/backlight/intel_backlight"
    cat "${br}/brightness"
}

function get_brightness {
    echo "brightness $(brightness)"
}

function showminutes {
    function pad {
        printf "%02d" "${1}"
    }
    local min hr
    min="${1}"
    if [[ "${1}" -gt 60 ]]; then
        hr="$(pad "$(( min / 60 ))")"
        min="$(pad "$(( min % 60 ))")"
        echo "${hr}:${min}"
    else
        echo "${min}m"
    fi
}

function get_battery {
    local bat bstatus clr capacity current timeleft chgstr tclr
    bat="/sys/class/power_supply/BAT${1}"
    if [[ "$(cat "${bat}/present")" -eq 1 ]]; then
        cat "${bat}/status" | read bstatus
        capacity="$(( $(cat "${bat}/charge_now") / 1000 ))"
        case "${bstatus}" in
            Full) 
                clr="$(dclr)" ;;
            Charging) 
                clr="$(dclr ${pa_hl})"
                ;;
            Discharging)
                clr="$(dclr ${pa_hl2})"
                current="$(( $(cat "${bat}/current_now") / 1000 ))"
                timeleft="$(( ( capacity * 60 ) / current ))"
                if [[ "${timeleft}" -gt 5 ]]; then
                    tclr="$(dclr ${pa_hl})"
                else
                    tclr="$(dclr ${pa_u})"
                fi
                chgstr="$(dclr)~${current}mA~${tclr}$(showminutes "${timeleft}")"
                ;;
            *) clr="$(dclr ${pa_u})" ;;
        esac
        echo "bat ${1} ${clr}${capacity}mAh${chgstr}$(dclr)"
    else
        echo "bat ${1} $(dclr):("
    fi
}

function get_mpd {
    local hr m_{status,volume,artist,album,title,str}
    case "${1}" in
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
            ;;
    esac
    echo "mpd ${m_str}"
}

if [[ -n "${1}" ]]; then
    eval "${@}"
fi
