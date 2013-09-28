#!/bin/zsh
cdir="$(readlink -f "$(dirname "${0}")")"
. "${cdir}/visual.sh"

function pafit {
    convert -resize "${pa_width}x${pa_height}>" "${1}" /tmp/temp_img
    convert -trim +repage /tmp/temp_img "${2}"
    rm -f /tmp/temp_img
}

mkdir -p "${bakeddir}"

# bake wallpaper
convert "${src_wallpaper}" "${baked_wallpaper}"

# bake panel background while emulating feh's --bg-fill option
convert -resize "${geometry[3]},${geometry[4]}^" \
        -gravity center -crop "${geometry[3]}x${geometry[4]}x0x0" +repage \
        -gravity NorthEast -crop "${pa_width}x${pa_height}+${pa_x}+${pa_y}" +repage \
        -blur 0x3 \
        -modulate 60,80,100 \
        "${baked_wallpaper}" "${baked_panelbg}"
convert -fill red -tint 20 "${baked_panelbg}" "${baked_panelbg_notif}"

# bake logo
pafit "${src_logo}" "${baked_logo}"
pafit "${srcdir}/m_playing.png" "${bakeddir}/m_playing.xpm"
pafit "${srcdir}/m_paused.png" "${bakeddir}/m_paused.xpm"
