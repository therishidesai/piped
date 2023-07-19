#!/usr/bin/env sh

trap "exit" INT TERM ERR
trap "kill 0" EXIT

if [ $# -ne 2 ]; then
    echo "usage: bw-test <NUM-WRITERS> <NUM-READERS>"
    exit 1
fi

writers=$1
readers=$2

piped &

sleep 5

for ((i=0; i < writers; i++))
do
    (od < /dev/urandom | pubmsg test &)
done

for ((i=0; i < readers-1; i++))
do
    echo "$i"
    (submsg | pv -a &>/dev/null &)
done

submsg | pv -a | head -c 1000000000 >/dev/null
