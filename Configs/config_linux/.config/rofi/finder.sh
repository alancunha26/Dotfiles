#!/usr/bin/env bash

fd . $HOME -t f -H -X echo -en "{}\0icon\x1fthumbnail://{}\n" |
rofi -dmenu -keep-right -i -p  |
xargs -I {} xdg-open {}
