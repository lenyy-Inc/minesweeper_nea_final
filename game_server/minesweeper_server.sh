#!/bin/sh
echo -ne '\033c\033]0;minesweeper_server\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/minesweeper_server.x86_64" "$@"
