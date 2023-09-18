#!/bin/bash
killall espeak
date +"Today is %A, %B %d, %Y" | espeak -z
exit 0
