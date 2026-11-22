#!/bin/sh

f=/sys/class/backlight/intel_backlight/brightness
touch $f || pkexec chmod a+w $f
br=$(cat $f) && br=$(expr $br - 2000) && echo $br > $f
