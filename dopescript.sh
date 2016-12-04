#!/bin/bash

function run(){
    prog=$1
    iters=$2
    echo -e "$iters \t"$({ time $(echo $iters | $prog >/dev/null); } 2>&1 | grep real | sed -e 's/.*m\([0-9]\+\.[0-9]\+\)s/\1/')
}

run ./imagefilter_c 1
run ./imagefilter_c 10
run ./imagefilter_c 25
run ./imagefilter_c 50
run ./imagefilter_c 150
run ./imagefilter_c 300
run ./imagefilter_c 500
run ./imagefilter_c 1000
run ./imagefilter_c 1500
