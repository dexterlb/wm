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

if [[ -n "${1}" ]]; then
    eval "${@}"
fi
