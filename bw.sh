#!/usr/bin/env sh

trap "exit" INT TERM ERR
trap "kill 0" EXIT

piped &

sleep 5

(od < /dev/urandom | pubmsg test &)

echo "start readers"
# 20 readers
#

for i in {0..8}
do
    echo "$i"
    (submsg | pv -a &>/dev/null &)
done

echo "start last reader"
submsg | pv -a | head -c 1000000000 >/dev/null

echo "kill all"
