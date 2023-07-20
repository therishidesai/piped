# -*- mode: bash-ts -*-

trap "exit" INT TERM ERR
trap "kill 0" EXIT

if [ $# -ne 2 ]; then
    echo "usage: bw-test <NUM-WRITERS> <NUM-READERS>"
    exit 1
fi

dir=$(mktemp --directory)

pushd "$dir"

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
    (submsg | pv -cNar >/dev/null &)
done

submsg | pv -cNar | head -c 1000000000 >/dev/null

popd
rm -rf "$dir"
