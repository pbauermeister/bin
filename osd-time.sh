#!/bin/sh
# Display time and battery when an app is full screen.
# apt install xdotool acpi aosd-cat

set -ex

DELAY=10

has_app_fullscreen() {
    root_geo="$(xwininfo -root | grep geometry)"
    [ "$(xwininfo -id $(xdotool getactivewindow) | grep geometry)" = "$root_geo" ]
}

make_text() {
    dir='+'; acpi | grep -q Discharging && dir='-' || true
    printf "%s %s %s\n" "`date '+%H:%M'`" "`acpi|awk -F, '{print $2}'`" "$dir"
    sleep 1
}

update_osd() {
    aosd_cat -n helvetica -u ${DELAY}000 \
	     -y -15 -x 15 \
	     -f 0 -o 0 -e 0 \
	     -r 255 -s 0 -b 0
}

run() {
    while true; do
	if has_app_fullscreen; then
	    make_text | update_osd
	else
	    sleep $DELAY
	fi
    done
}

run
