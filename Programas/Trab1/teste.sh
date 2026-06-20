#!/bin/bash

set -e

RUNS=10
THREADS=4

rm -f tempos.csv

for N in 1024 2048 3072 4096
do
    echo "====================================="
    echo "Generating N=$N"
    echo "====================================="

    ./gera_arquivos $N

    ls -lh matrizA.bin vetorB.bin

    for RUN in $(seq 1 $RUNS)
    do
        echo "N=$N RUN=$RUN"

        ./equation \
            -m matrizA.bin \
            -v vetorB.bin \
            -n $N \
            -t 128 \
            -g 256 \
            -T $THREADS
    done
done