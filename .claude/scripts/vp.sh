#!/usr/bin/env bash
# Usage:
#   vp.sh shot TARGET OUT.png      TARGET is a layer namespace (waybar, swaync) or a grim geometry "x,y wxh"
#   vp.sh boxes IMG.png [MINAREA]  bounding boxes (WxH+X+Y) of everything that differs from the corner pixel
#   vp.sh diff BASE.png NEW.png [DIFF.png]   exit 0 only when no pixel differs
set -euo pipefail

geometry() {
  if [[ $1 == *,*\ *x* ]]; then echo "$1"; return; fi
  hyprctl layers -j | jq -er --arg ns "$1" \
    'first(.. | objects | select(.namespace? == $ns)) | "\(.x),\(.y) \(.w)x\(.h)"' ||
    { echo "no layer named '$1' (see: hyprctl layers -j)" >&2; exit 2; }
}

case ${1:-} in
  shot)
    [[ $# -eq 3 ]] || { echo "usage: vp.sh shot TARGET OUT.png" >&2; exit 2; }
    g=$(geometry "$2"); grim -g "$g" "$3"; echo "$3 $g"
    ;;
  boxes)
    [[ $# -ge 2 ]] || { echo "usage: vp.sh boxes IMG.png [MINAREA]" >&2; exit 2; }
    bg=$(magick "$2" -format '%[pixel:p{0,0}]' info:)
    magick "$2" -alpha off -fuzz 12% -fill black -opaque "$bg" -fill white +opaque black \
      -define connected-components:verbose=true -define connected-components:area-threshold="${3:-6}" \
      -connected-components 8 null: | awk '/srgb\(255,255,255\)|gray\(255\)/ {print $2}' | sort -t+ -k2,2n
    ;;
  diff)
    [[ $# -ge 3 ]] || { echo "usage: vp.sh diff BASE.png NEW.png [DIFF.png]" >&2; exit 2; }
    sa=$(magick identify -format '%wx%h' "$2"); sb=$(magick identify -format '%wx%h' "$3")
    [[ $sa == "$sb" ]] || { echo "size differs: $sa vs $sb"; exit 1; }
    n=$(magick "$2" "$3" -alpha off -compose difference -composite -grayscale Rec709Luma -threshold 0 \
      -format '%[fx:round(mean*w*h)]' info:)
    [[ -n ${4:-} ]] && magick compare "$2" "$3" "$4" 2>/dev/null || true
    echo "differing pixels: $n"; [[ $n == 0 ]]
    ;;
  *) sed -n '2,5p' "$0" >&2; exit 2 ;;
esac
