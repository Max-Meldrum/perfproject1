#!/bin/bash

function run(){
    prog=$1
    iters=$2
    min=99999.0
    max=0
    sum=0
    for i in $(seq 1 10); do
        t=$({ time $(echo $iters | $prog >/dev/null); } 2>&1 | grep real | sed -e 's/.*m\([0-9]\+\.[0-9]\+\)s/\1/')
        sum=$(bc -l <<< "$sum+$t")
        if [ $(bc -l <<< "$t<$min") -eq 1 ]; then
            min=$t
        fi
        if [ $(bc -l <<< "$t>$max") -eq 1 ]; then
            max=$t
        fi
    done
    res=$(bc -l <<< "$sum/10")
    echo -e "$iters\t$res\t$min\t$max"
    #echo -e "$iters \t"$({ time $(echo $iters | $prog >/dev/null); } 2>&1 | grep real | sed -e 's/.*m\([0-9]\+\.[0-9]\+\)s/\1/')
}

# Warmup processor
echo "Ramping up CPU scheduler for stress test"
echo 1000 | ./imagefilter_c >/dev/null

# GO!
echo "Starting benchmark"
run ./imagefilter_c 1
run ./imagefilter_c 10
run ./imagefilter_c 25
run ./imagefilter_c 50
run ./imagefilter_c 150
run ./imagefilter_c 300
run ./imagefilter_c 500
run ./imagefilter_c 1000
run ./imagefilter_c 1500
