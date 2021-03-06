#!/usr/bin/env bash

# Format:
#
# Each line could be preceded by whitespace. This can still easily be parsed by
# languages (including C with scanf), and it allows for either a more
# compressed file size or indentation to make it more readable.
#
# Date/Time (Unix timestamp)
#   Uptime (seconds)
#   1-min-load-avg 5-min-load-avg 15-min-load-avg
#   Available memory (kB)
#   Number of unique users
#   Number of listed users
#   For each listed user:
#       Username
#       Displays and TTYs
#       Screensaver programs
#       Number of zombies
#       Interesting programs:
#           chrome  0
#           firefox 1
#           csh     2
#           bash    3
#           zsh     4
#           vim     5
#           emacs   6
#           gedit   7
#           sublime 8
#           nano    9
#           tmux    a
#           screen  b
#       Number of processes
#       Number of threads
#       Number of thread-heavy processes*
#       For each thread-heavy process:
#           Number of threads <SPACE> Secs since start <SPACE> Cmd line
#       Number of CPU-heavy processes**
#       For each CPU-heavy process:
#           Avg CPU percent <SPACE> Secs since start <SPACE> Cmd line
#       Number of memory-heavy processes***
#       For each memory-heavy process:
#           Mem usage (kB) <SPACE> Secs since start <SPACE> Cmd line
#
#   * A process with >=100 threads
#  ** A process that has an avg CPU usage of over 90%, and has been running for
#  at least a minute
# *** A process that is using over 1GB of memory

current_date=$(date +%s)
computer_name="$(hostname -s)"

indent()
{
    local line
    while IFS= read -r line; do
        printf '\t%s\n' "$line"
    done
}

computer_uptime()
{
    echo $(($(date +%s) - $(date -d "$(uptime -s)" +%s)))
}

load_avgs()
{
    uptime | awk -F'[,:] ' '{print $(NF-2), $(NF-1), $NF}'
}

meminfo()
{
    awk -F':? +' "\$1 == \"$1\" {print \$2}" /proc/meminfo
}

mem_avail()
{
    meminfo MemAvailable
}

# $1 should be the username for all user_* functions

user_logins()
{
    local logins
    logins="$(who | awk '$1 == "'$1'" {print $2}' | sort -u)"
    echo $logins
}

user_lock_programs()
{
    local xpid lock_pgrms
    xpid="$(ps -u "$1" -o comm,pid | awk '$1 == "xscreensaver" {print $2}')"
    lock_pgrms="$(ps -u "$1" -o ppid,comm | \
        awk "\$1 == \"$xpid\" {print \$2}")"
    if ps -u "$1" -o comm | grep -q "^xlock$"; then
        lock_pgrms="$lock_pgrms xlock"
    fi
    echo $lock_pgrms
}

user_n_zombies()
{
    ps -u "$1" -o state | grep -cF Z
}

user_pgrms()
{
    local comms pgrms
    comms="$(ps -u "$1" -o comm)"
    pgrms=
    grep -q '^chrome$'  <<<"$comms" && pgrms="$pgrms 0"
    grep -q '^firefox$' <<<"$comms" && pgrms="$pgrms 1"
    grep -q 'csh$'      <<<"$comms" && pgrms="$pgrms 2"
    grep -q 'bash$'     <<<"$comms" && pgrms="$pgrms 3"
    grep -q 'zsh$'      <<<"$comms" && pgrms="$pgrms 4"
    grep -q 'vim\?$'    <<<"$comms" && pgrms="$pgrms 5"
    grep -q '^emacs$'   <<<"$comms" && pgrms="$pgrms 6"
    grep -q '^gedit$'   <<<"$comms" && pgrms="$pgrms 7"
    grep -q '^subl$'    <<<"$comms" && pgrms="$pgrms 8"
    grep -q '^nano$'    <<<"$comms" && pgrms="$pgrms 9"
    grep -q '^tmux$'    <<<"$comms" && pgrms="$pgrms a"
    grep -q '^screen$'  <<<"$comms" && pgrms="$pgrms b"
    echo $pgrms
}

trim()
{
    sed 's/^\s\s*//; s/\s\s*$//; s/\s\{2,\}/ /'
}

user_n_procs()
{
    ps -u "$1" -o pid --no-headers | wc -l
}

user_n_threads()
{
    ps -u "$1" -o nlwp --no-headers | awk '{sum += $1} END {print sum}'
}

user_threads()
{
    local threads n
    threads="$(ps -u "$1" -o nlwp,etimes,cmd --no-headers | awk '$1 >= 100' | \
        trim)"
    n="$(wc -l <<<"$threads")"
    if [ -n "$threads" ]; then
        echo $n
        indent <<<"$threads"
    else
        echo 0
    fi
}

user_cpu_procs()
{
    local procs n
    procs="$(ps -u "$1" -o %cpu,etimes,cmd --no-headers | \
        awk '$1 > 90 && $2 > 60' | trim)"
    n="$(wc -l <<<"$procs")"
    if [ -n "$procs" ]; then
        echo $n
        indent <<<"$procs"
    else
        echo 0
    fi
}

user_mem_procs()
{
    local procs n
    procs="$(ps -u "$1" -o rss,etimes,cmd --no-headers | awk '$1 > 1048576' | trim)"
    n="$(wc -l <<<"$procs")"
    if [ -n "$procs" ]; then
        echo $n
        indent <<<"$procs"
    else
        echo 0
    fi
}

user_info()
{
    echo "$1"
    (
        user_logins "$1"
        user_lock_programs "$1"
        user_n_zombies "$1"
        user_pgrms "$1"
        user_n_procs "$1"
        user_n_threads "$1"
        user_threads "$1"
        user_cpu_procs "$1"
        user_mem_procs "$1"
    ) | indent
}

computer_info()
{
    local running_users
    computer_uptime
    load_avgs
    mem_avail
    users | tr ' ' '\n' | sort -u | wc -l
    running_users="$(grep -Ff <(ps -o user -e --no-headers | sort -u) <(ls /u/))"
    wc -l <<<"$running_users"
    for user in $running_users; do
        user_info "$user"
    done | indent
}

out="$(echo ${current_date}; computer_info | indent)"
dir="$HOME/.computer-info"

case "$1" in
    (--file)
        file="$dir/$computer_name-${current_date}.txt"
        printf "%s\n" "$out" >"$file"
        touch "$file.done"
        ;;

    (--daemon)
        mkdir -p "$dir"
        cd "$dir"
        main_file="$computer_name.txt.xz"
        if [[ ! -f "$main_file" ]]; then
            txt_file="$computer_name.txt"
            touch "$txt_file"
            xz "$txt_file"
        else
            ./analyze-computer-info compress "$computer_name"
        fi
        tmp_file="$computer_name-tmp.txt"
        while sleep 300; do
            files="$(find -name "$computer_name-*.txt.done" | sort \
                | sed 's/\.done$//')"
            for file in $files; do
                (xz -cd "$main_file"; cat "$file") | \
                    xz >"$tmp_file" && mv "$tmp_file" "$main_file"
                cp "$file" "$computer_name-current.txt"
                rm "$file" "$file.done"
            done
        done
        ;;

    (*)
        echo "$out"
        ;;
esac
