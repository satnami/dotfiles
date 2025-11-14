#!/usr/bin/env bash

find . -type f -exec md5sum {} + | sort | uniq -w32 -dD
