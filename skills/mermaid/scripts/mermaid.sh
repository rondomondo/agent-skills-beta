#!/usr/bin/env bash
# mermaid - render mermaid diagrams from markdown via Docker (minlag/mermaid-cli)
#
# Usage:
#   mermaid <input.md> [options]
#
# Options:
#   -f, --format <fmt>    Output format: svg (default), png, pdf
#   -t, --theme <theme>   Mermaid theme: default, dark, forest, neutral
#   -b, --bg <color>      Background colour (e.g. white, transparent, '#f5f5f5')
#   -w, --width <px>      Diagram width in pixels
#   -H, --height <px>     Diagram height in pixels
#   -s, --scale <n>       Pixel density / scale factor (default 1 - or 3 for retina/HiDPI)
#   -d, --dir <dir>       Host directory to mount (defaults to directory of input file)
#   -h, --help            Show this help
#
# Examples:
#   mermaid data/example.md
#   mermaid data/example.md -f png
#   mermaid data/example.md --format png  --scale 3   # retina/HiDPI
#   mermaid data/example.md --format png  --width 960 --height 640 --bg #99aacc
#   mermaid data/example.md -f svg -b transparent -w 1920

mermaid() {
  local input=""
  local format="svg"
  local theme=""
  local bg=""
  local width=""
  local height=""
  local scale=""
  local mount_dir=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--format)  format="${2:?--format requires a value}";  shift 2 ;;
      -t|--theme)   theme="${2:?--theme requires a value}";    shift 2 ;;
      -b|--bg)      bg="${2:?--bg requires a value}";          shift 2 ;;
      -w|--width)   width="${2:?--width requires a value}";    shift 2 ;;
      -H|--height)  height="${2:?--height requires a value}";  shift 2 ;;
      -s|--scale)   scale="${2:?--scale requires a value}";    shift 2 ;;
      -d|--dir)     mount_dir="${2:?--dir requires a value}";  shift 2 ;;
      -h|--help)    local _src; [[ -n "${ZSH_VERSION}" ]] && _src="${(%):-%x}" || _src="${BASH_SOURCE[0]}"
                    sed -n '3,/^mermaid/{ /^mermaid/d; s/^# \{0,1\}//; p }' "$_src" 2>/dev/null \
                      || grep '^#' $_src | sed 's/^# \{0,1\}//'; return 0 ;;
      -*)           echo "mermaid: unknown option: $1" >&2; return 1 ;;
      *)            input="$1"; shift ;;
    esac
  done


  if [[ -z "$input" ]]; then
    echo "mermaid: input file required" >&2
    echo "Usage: mermaid <input.md> [-f svg|png|pdf] [...]" >&2
    return 1
  fi

  if [[ ! -f "$input" ]]; then
    echo "mermaid: file not found: $input" >&2
    return 1
  fi


  local abs_input
  abs_input="$(cd "$(dirname "$input")" && pwd)/$(basename "$input")"

  [[ -z "$mount_dir" ]] && mount_dir="$(dirname "$abs_input")"

  local basename filename stem output
  basename="$(basename "$abs_input")"

  # strip trailing .md to get the stem, then rebuild with format before .md
  # e.g. diagram.md → diagram.<format>.md
  #      diagram.md.new.md → diagram.md.new.<format>.md
  if [[ "$basename" == *.md ]]; then
    stem="${basename%.md}"           # strip last .md
    filename="${stem}.${format}.md"  # insert format before .md
  else
    filename="${basename}.${format}.md"
  fi

  # the container only sees files under /data
  local container_input="/data/${basename}"
  local container_output="/data/${filename}"

  local extra_args=()
  [[ -n "$theme"  ]] && extra_args+=("--theme"           "$theme")
  [[ -n "$bg"     ]] && extra_args+=("--backgroundColor" "$bg")
  [[ -n "$width"  ]] && extra_args+=("--width"           "$width")
  [[ -n "$height" ]] && extra_args+=("--height"          "$height")
  [[ -n "$scale"  ]] && extra_args+=("--scale"           "$scale")
  [[ -n "$format" ]] && extra_args+=("--outputFormat"          "$format")

  echo "mermaid: rendering '${basename}' → '${filename}' (${format})" >&2

  docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "${mount_dir}:/data" \
    minlag/mermaid-cli \
    -i "$container_input" \
    -o "$container_output" \
    "${extra_args[@]}" >&2

  local rc=$?
  if [[ $rc -eq 0 ]]; then
    echo "mermaid: written → ${mount_dir}/${filename}" >&2
  else
    echo "mermaid: docker exited with code $rc" >&2
  fi
  return $rc
}


