#!/usr/bin/env bash

rofi \
    -modi clipboard:$HOME/.local/bin/cliphist-rofi-img \
    -theme $HOME/.config/rofi/clipboard.rasi \
    -show clipboard \
    -show-icons

