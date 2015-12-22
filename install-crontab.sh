#!/usr/bin/env bash

crontab="$(crontab -l 2>/dev/null)"

while read -r line; do
    grep -qF "$line" <<<"$crontab" && continue
    crontab="$(echo "$line"; echo "$crontab")"
done <<<"$(tac crontab.txt)"

crontab="$(grep '^@reboot ' <<<"$crontab"; grep -v '^@reboot ' <<<"$crontab")"

crontab - <<<"$crontab"
