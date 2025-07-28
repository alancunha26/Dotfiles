#!/usr/bin/env bash

fd . $HOME -t f -H -X echo -en "{}\0icon\x1fthumbnail://{}\n" |
rofi -dmenu -keep-right -i -p  -theme ./finder.rasi |
xargs -I {} xdg-open {}
