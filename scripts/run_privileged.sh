#!/usr/bin/env bash
# Helper script to execute privileged (sudo/polkit) commands in a dedicated interactive Kitty window
if [ -z "$*" ]; then
    kitty --title "Privileged Terminal" bash
else
    kitty --title "Privileged Command: $*" bash -c "$*; echo ''; echo 'Done. Press Enter to close.'; read"
fi
