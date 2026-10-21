#!/usr/bin/env bash

rofi \
  -show calc \
  -modi calc \
  -no-show-match \
  -no-sort \
  -calc-command "echo -n '{result}' | wl-copy" \
  -theme $HOME/.config/rofi/calculator.rasi
