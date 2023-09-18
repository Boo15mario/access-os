#!/bin/bash
killall espeak
date +"It's %I:%M %P %Z" | espeak -z
exit 0
