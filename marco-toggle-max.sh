#!/bin/bash
#
# This script toggles the focused window between normal position and
# full/vertically/horizontally-maximized.
#
# If the window is already maximized in any orientation, it first goes
# back to normal position. It then needs a second call to be maximized
# in the desired orientation. So it does never goes from
# e.g. horizontally-maxed to vertically-maxed.
#
# Bind Your Keyboard Shortcuts:
# - Open Control Center > Keyboard Shortcuts.
# - Scroll to the bottom and click Add to create three custom
#   shortcuts (replace YOUR_USER with your actual Linux username):
#        Name: Toggle Maximize (Smart)
#        Command: /home/YOUR_USER/bin/marco-toggle-max.sh full
#        Shortcut: shift+ctrl+alt+space
#
#        Name: Toggle Maximize Vertically (Smart)
#        Command: /home/YOUR_USER/bin/marco-toggle-max.sh vert
#        Shortcut: shift+ctrl+space
#
#        Name: Toggle Maximize Horizontally (Smart)
#        Command: /home/YOUR_USER/bin/marco-toggle-max.sh horz
#        Shortcut: ctrl+alt+space
#
# FIXME: does not work correctly on monitor having no system toolbar
# FIXME: should consider the widow decorations thickness, incl. side borders

MODE="$1" # vert, horz, or full
WIN=$(xdotool getactivewindow)
[ -z "$WIN" ] && exit 1

STATE=$(xprop -id "$WIN" _NET_WM_STATE)
STATE_FILE="/tmp/marco_toggle_${WIN}"
LOG_FILE="/tmp/marco_toggle.log"

get_top_margin() {
    local win_x="$1"
    local id strut top start_x end_x
    for id in $(xdotool search --class mate-panel 2>/dev/null); do
        strut=$(xprop -id "$id" _NET_WM_STRUT_PARTIAL 2>/dev/null | awk -F'= ' '{print $2}' | tr -d ' ')
        [ -z "$strut" ] && continue
        IFS=',' read -r _ _ top _ _ _ _ _ start_x end_x _ _ <<< "$strut"
        if [ "${top:-0}" -gt 0 ] && [ "$win_x" -ge "$start_x" ] && [ "$win_x" -le "$end_x" ]; then
            echo "$top"
            return
        fi
    done
    echo 0
}

is_maximized_desired() {
    case "$MODE" in
	vert) echo "$STATE" | grep -q "_NET_WM_STATE_MAXIMIZED_VERT" ;;
	horz) echo "$STATE" | grep -q "_NET_WM_STATE_MAXIMIZED_HORZ" ;;
	full) echo "$STATE" | grep -q "_NET_WM_STATE_MAXIMIZED_VERT" && echo "$STATE" | grep -q "_NET_WM_STATE_MAXIMIZED_HORZ" ;;
	*) exit 1 ;;
    esac
}

is_maximized_any() {
    echo "$STATE" | grep -q "_NET_WM_STATE_MAXIMIZED_VERT" && return 0
    echo "$STATE" | grep -q "_NET_WM_STATE_MAXIMIZED_HORZ" && return 0
    return 1
}

case "$MODE" in
    vert) FLAG="maximized_vert" ;;
    horz) FLAG="maximized_horz" ;;
    full) FLAG="maximized_vert,maximized_horz" ;;
    *) exit 1 ;;
esac

unmaximize() {
    echo ">>> unmaximizing: 0"
    # Unmaximize and restore the saved tiled/normal geometry
    wmctrl -i -r "$WIN" -b remove,maximized_vert,maximized_horz

    if [ ! -f "$STATE_FILE" ]; then
	echo "No saved pos."
	return
    fi

    read -r X Y W H < "$STATE_FILE"

    GEOM=$(xwininfo -id "$WIN")
    x=$(echo "$GEOM" | awk '/Absolute upper-left X:/ {print $4}')
    y=$(echo "$GEOM" | awk '/Absolute upper-left Y:/ {print $4}')

    # keep axis that was not maxed, into new normal state
    top_margin=$(get_top_margin $x)
    echo "top_margin $x = $top_margin"
    case "$FLAG" in
	maximized_vert)
	    X=$x  # X from live
	    ;;
	maximized_horz)
	    Y=$y  # Y from live
	    Y=$((Y - $top_margin))
	    ;;
	"maximized_vert,maximized_horz")
	    ;;
    esac

    wmctrl -i -r "$WIN" -e "0,$X,$Y,$W,$H"
    rm -f "$STATE_FILE"

    echo "> Unmaxed."
}

maximize_desired() {
    # Save current geometry directly using xwininfo
    GEOM=$(xwininfo -id "$WIN")
    X=$(echo "$GEOM" | awk '/Absolute upper-left X:/ {print $4}')
    Y=$(echo "$GEOM" | awk '/Absolute upper-left Y:/ {print $4}')
    top_margin=$(get_top_margin $X)
    echo "top_margin $X = $top_margin"
    Y=$((Y - $top_margin))
    WIDTH=$(echo "$GEOM" | awk '/Width:/ {print $2}')
    HEIGHT=$(echo "$GEOM" | awk '/Height:/ {print $2}')

    echo "$X $Y $WIDTH $HEIGHT" > "$STATE_FILE"

    wmctrl -i -r "$WIN" -b "add,$FLAG"
    cat "$STATE_FILE"
    echo "> Maxed."
}

doit_1() {
    # toggles between max and normal
    if is_maximized_any; then
	echo "Is maxed."
	unmaximize
    else
	echo "Is not maxed."
	maximize_desired
    fi
}

doit_2() {
    # toggles anything and desired max (may move between two maxes:
    # other-max to desired-max)
    if is_maximized_desired; then
	echo "Is maxed as desired => unmax"
	unmaximize
    else
	echo "Is NOT maxed as desired => will max"
	if is_maximized_any; then
	    echo "But is maxed, however not as desired => first, unmax"
	    unmaximize
	fi
	echo "=> max"
	maximize_desired
    fi
}

doit () {
    echo "===== EVENT: $MODE ====="
    echo "$STATE"
    doit_2
}

doit > "$LOG_FILE" 2>&1
