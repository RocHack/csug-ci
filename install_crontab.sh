#!/bin/bash

# check current crontab to see if we've already installed it
# TODO

# append the file to the current crontab 
# from http://stackoverflow.com/questions/8579330/appending-to-crontab-with-a-shell-script-on-ubuntu
(crontab -l 2>/dev/null ; cat crontab.txt) | crontab -

