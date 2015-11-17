#!/usr/bin/env bash

# Format:
#
# Each line could be preceded by whitespace. This can still easily be parsed by
# languages (including C with scanf), and it allows for either a more
# compressed file size or indentation to make it more readable.
#
# Date/Time (TODO - what format? Unix timestamp, probably?)
# For each computer:
#   Name
#   Uptime (TODO - format?)
#   1-min-load-avg 5-min-load-avg 15-min-load-avg
#   Available memory
#   Number of unique users
#   For each unique user:
#       Username
#       Number of times logged in (to same computer at same time)
#       Time idle (TODO - best way to determine this?)
#       Number of running programs (plus zombies)
#       For each running program:
#           Command line
#       `   State (i.e. zombie, running, stopped, etc.)
#           Start date/time (same format as beginning) (TODO - format?)
# Blank line

# Format:
#
# Each line could be preceded by whitespace. This can still easily be parsed by
# languages (including C with scanf), and it allows for either a more
# compressed file size or indentation to make it more readable.
#
# Date/Time (TODO - what format? Unix timestamp, probably?)
# For each computer:
#   Name
#   Uptime (TODO - format? Just the number of seconds?)
#   1-min-load-avg 5-min-load-avg 15-min-load-avg
#   Available memory
#   Number of unique users
#   For each unique user:
#       Username
#       Number of times logged in (to same computer at same time)
#       screensaver programs
#       "Z" + Number of zombies (optional)
#       List of interesting programs running:
#           chrome, firefox, tmux, screen, zsh, vim, emacs, gedit, sublime,
#           atom, (TODO - other editors?), (TODO - other programs?)
# Blank line

# for now:
# <number of users> <list of users>

# from http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
folder="computers"
cd $dir
computer=$(hostname -s)
users=$(users | tr ' ' '\n' | sort -u)
number=$(echo $users | wc -l)
echo "$number $users" >> "$folder/$computer.txt"
