#!/bin/bash

declare -A ARGUMENTS=( [name]=system_root [path]=/ )
source kwargs.sh "{'name'='system_root','path'='/'}" "$@"

echo "final answer is name $name path $path"
