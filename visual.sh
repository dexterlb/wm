#!/bin/zsh
cdir="$(readlink -f "$(dirname "$0")")"

col_hl='ebac54'
col_hl2='7cd4fc'
col_norm='efebe5'
col_inactive='584C3A'

pa_default=( "${col_norm}" '1b1d1e' )
pa_outline=( '5493EB' '' )
pa_hl=( "${col_hl}" '' )
pa_hl2=( "${col_hl2}" '' )
pa_u=( 'ffffff' 'd12525' )
pa_active=( "${col_hl}" '')
pa_inactive=( "${col_inactive}" '')

# several things assume that the font is monospace: fixme
xft='Droid Sans Mono-12'
#pa_font="${xft}"
pa_font='-*-droid sans mono-*-*-*-*-15-*-*-*-*-*-*-*'


. ~/.mpd_data.sh

if [[ -z ${monitor} ]]; then
    monitor=0
fi
geometry=( $(herbstclient monitor_rect "$monitor") )
if [ -z "$geometry" ] ;then
    echo "Invalid monitor $monitor"
    exit 1
fi
escgeometry="$(echo "${geometry[@]}" | perl -pe 's/ /_/g')"
# geometry has the format: WxH+X+Y
pa_x=${geometry[1]}
pa_y=${geometry[2]}
pa_height=24
pa_width=${geometry[3]}

imgdir="${cdir}/images"
xbmdir="${imgdir}/xbm"
bakeddir="${imgdir}/baked"
srcdir="${imgdir}/src"

baked_wallpaper="${bakeddir}/wallpaper.png"
src_wallpaper="${srcdir}/wallpaper/portal_coop_desat.png"
baked_panelbg="${bakeddir}/panelbg_${escgeometry}.xpm"
baked_panelbg_notif="${bakeddir}/panelbg_notif_${escgeometry}.xpm"
src_logo="${srcdir}/logo.png"
baked_logo="${bakeddir}/logo.xpm"

function imgsize {
    if [[ ! -f "${1}.size" ]]; then
        identify "${1}" | read trash trash size trash
        echo "${size}" | perl -pe 's/[xX]/ /g' > "${1}.size"
    fi
    cat "${1}.size"
}

function imgwidth {
    imgsize "${1}" | read width trash
    echo "${width}"
}

charwidth=$(textwidth "${pa_font}" a)

function mono_textwidth {
    echo $(( charwidth * $(echo -n "${1}" | wc -m) ))
}

function pawidth {
    # fixme: this will fail badly if there is a string that ends with ^^
    text=$(mono_textwidth "$(echo -n "${1}" | sed 's.\^[^(]*([^)]*)..g')")
    rel=$(echo "${1}" | perl -ne 'my $n = 0; foreach (m/(?<!\^)\^p\(([^)]+)\)/g) { $n += $_ }; print $n')
    rect=$(echo "${1}" | perl -ne 'my $n = 0; foreach (m/(?<!\^)\^r(o?)\(([0-9]+)[xX][0-9]+\)/g) { $n += $_ }; print $n')
    cir=$(echo "${1}" | perl -ne 'my $n = 0; foreach (m/(?<!\^)\^c(o?)\(([0-9]+)\)/g) { $n += $_ }; print ($n*2)')
    img=0
    echo "${1}" | perl -ne 'foreach (m/(?<!\^)\^i\(([^)]+)\)/g) { print "$_\0" }' \
        | while read -d $'\0' i; do
            img=$((img + $(imgwidth "${i}") ))
        done
    echo $((text + rel + rect + cir + img))
}

function dclr {
    if [[ -n "${1}" ]]; then
        echo -n "^fg(#${1})"
    else
        echo -n "^fg()"
    fi
    if [[ -n "${2}" ]]; then
        echo -n "^bg(#${2})^ib(0)"
    else
        echo -n "^bg()^ib(1)"
    fi
}


dzen_common=(
    -bg "#$pa_default[2]"
    -fg "#$pa_default[1]"
    -fn "$pa_font"
    -h  "$pa_height"
    -e  "button1=exec:$cdir/session_menu.sh" )
