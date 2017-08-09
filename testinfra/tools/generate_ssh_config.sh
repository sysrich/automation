#!/bin/sh
cat $1/tools/ssh_config.example | sed "s|%PATH%|$1/tools|" > $1/tools/ssh_config