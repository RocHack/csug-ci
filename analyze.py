#!/usr/bin/env python3

import os
import sys
import fnmatch
from decimal import Decimal

# Based on http://stackoverflow.com/questions/1724693/find-a-file-in-python
def find(pattern, path):
    results = []
    for root, dirs, files in os.walk(path):
        for name in files:
            if fnmatch.fnmatch(name, pattern):
                results.append(os.path.join(root, name))
    return results

def usage(cmd, status=None):
    if cmd is None:
        print("usage: analyze-computer-info COMMAND [--help] OPTIONS")
    if status is not None:
        sys.exit(status)

def parse_args(argv):
    argc = len(argv)
    files = {}
    i = 1
    while True:
        computer = argv[i]
        if computer == "--":
            i += 1
            break
        f = argv[i + 1]
        files[computer] = f
        i += 2

    if i >= argc:
        usage(None, 1)
    cmd = argv[i]
    if cmd == "--help" or cmd == "-h":
        usage(None, 0)
    i += 1

    info = {'computers': [], 'files': files}
    while i < argc:
        arg = argv[i]
        i += 1
        if arg == "--help" or arg == "-h":
            usage(cmd, 0)
        # For now, each addition argument is only specifying the computer; this
        # will change
        info['computers'].append(arg)

    return cmd, info

def read_line(f, allow_blank=True):
    line = f.readline()
    if not allow_blank:
        while line == "\n":
            line = f.readline()
    if line == "":
        return None
    return line.strip()

pgrm_map = {
    '0': 'chrome',
    '1': 'firefox',
    '2': 'csh',
    '3': 'bash',
    '4': 'zsh',
    '5': 'vim',
    '6': 'emacs',
    '7': 'gedit',
    '8': 'sublime',
    '9': 'nano',
    'a': 'tmux',
    'b': 'screen'
}

def parse_interesting_pgrms(f, user):
    line = read_line(f)
    user['pgrms'] = map(lambda x: pgrm_map[x], line.split(' '))

def parse_user(f, prev, datum):
    user = {}
    line = read_line(f)
    username = line
    user['username'] = username
    line = read_line(f)
    if prev is not None and line == "-1":
        user = prev['users'][username]
        datum['users'][username] = user
        return
    user['logins'] = line.split(' ')
    line = read_line(f)
    user['screensavers'] = line.split(' ')
    line = read_line(f)
    user['zombies'] = int(line)
    parse_interesting_pgrms(f, user)
    line = read_line(f)
    user['processes'] = int(line)
    line = read_line(f)
    user['threads'] = int(line)
    line = read_line(f)
    n_thread_procs = int(line)
    user['thread_procs'] = []
    for i in range(n_thread_procs):
        line = read_line(f)
        array = line.split(' ')
        user['thread_procs'].append({
            'n_threads': int(array[0]),
            'secs': int(array[1]),
            'cmd': ' '.join(array[2:])
        })
    line = read_line(f)
    n_cpu_procs = int(line)
    user['cpu_procs'] = []
    for i in range(n_cpu_procs):
        line = read_line(f)
        array = line.split(' ')
        user['cpu_procs'].append({
            'avg_cpu': int(array[0]),
            'secs': int(array[1]),
            'cmd': ' '.join(array[2:])
        })
    line = read_line(f)
    n_mem_procs = int(line)
    user['mem_procs'] = []
    for i in range(n_mem_procs):
        line = read_line(f)
        array = line.split(' ')
        user['mem_procs'].append({
            'mem_usage': int(array[0]),
            'secs': int(array[1]),
            'cmd': ' '.join(array[2:])
        })
    datum['users'][username] = user

def parse_computer(f, prev, datum):
    line = read_line(f, False)
    if line is None:
        return None
    datum['time'] = int(line)
    line = read_line(f)
    datum['uptime'] = int(line)
    line = read_line(f)
    loads = line.split(' ')
    datum['load_avgs'] = (Decimal(loads[0]), Decimal(loads[1]),
            Decimal(loads[2]))
    line = read_line(f)
    datum['avail_mem'] = int(line)
    line = read_line(f)
    datum['uniq_users'] = int(line)
    line = read_line(f)
    n = int(line)
    if prev is not None and n < 0:
        datum['users'] = prev['users']
    else:
        datum['users'] = {}
        for i in range(n):
            parse_user(f, prev, datum)
    return datum

def load_one(f, prev):
    datum = {}
    return parse_computer(f, prev, datum)

def load_start_end(f, start, end):
    data = []
    prev = None
    recording = False
    with open(f, "r") as computer:
        while True:
            datum = load_one(computer, prev)
            if datum is None:
                return data
            if not recording and start(datum):
                recording = True
            if recording and end(datum):
                return data
            if recording:
                data.append(datum)
            prev = datum

def load_all(f):
    return load_start_end(f, lambda x: True, lambda x: False)

def compress_computer(computer, f):
    data = load_all(f)

def cmd_compress(info):
    for computer in info['computers']:
        compress_computer(computer, info['files'][computer])

def exec_cmd(cmd, info):
    if cmd == "compress":
        cmd_compress(info)

def main():
    return
    cmd, info = parse_args(sys.argv)
    exec_cmd(cmd, info)

if __name__ == "__main__":
    main()
