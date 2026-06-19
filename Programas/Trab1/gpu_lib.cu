#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include "comum.h"
#include "gpu.h"

void *threadFunc(void *arg) {
    threadArgs_t *args = (threadArgs_t *)arg;

    int t = args->threadId;
    data_t *hmA = args->hmA;
    data_t *hvB = args->hvB;
    int nIncognitas = args->nIncognitas;
    int passo = args->passo;

    int linhasThread = (nIncognitas - passo) / nThreads;
    int resto = (nIncognitas - passo) % nThreads;
    int QtdLinhas = linhasThread + (t < resto ? 1 : 0);
    int LinhaInicial = passo + t * linhasThread + (t < resto ? t : resto);
    int LinhaFinal = LinhaInicial + QtdLinhas;

    for(int linha = LinhaInicial; linha < LinhaFinal; linha++) {
        data_t multiplicador = matriz(hmA, linha, passo-1, nIncognitas)
                             / matriz(hmA, passo-1, passo-1, nIncognitas);
        for(int coluna = passo-1; coluna < nIncognitas; coluna++) {
            matriz(hmA, linha, coluna, nIncognitas) -=
                matriz(hmA, passo-1, coluna, nIncognitas) * multiplicador;
        }
        hvB[linha] -= hvB[passo-1] * multiplicador;
    }

    threadReturn_t *ret = (threadReturn_t *)malloc(sizeof(threadReturn_t));
    ret->status = 0;
    pthread_exit(ret);
}

void processaVetoresThread(data_t *hmA, data_t *hvB, int nIncognitas) {
    pthread_t threads[nThreads];
    threadArgs_t args[nThreads];
    threadReturn_t *ret;

    for(int passo = 1; passo < nIncognitas; passo++) {

        for(int t = 0; t < nThreads; t++) {
            args[t].threadId    = t;
            args[t].hmA         = hmA;
            args[t].hvB         = hvB;
            args[t].nIncognitas = nIncognitas;
            args[t].passo       = passo;
            pthread_create(&threads[t], NULL, threadFunc, &args[t]);
        }

        for(int t = 0; t < nThreads; t++) {
            pthread_join(threads[t], (void **)&ret);
            free(ret);
        }

    }
}

__global__
void eliminaPassoKernel(data_t *dA, data_t *dB, int nIncognitas, int passo){
    int linha = passo + blockIdx.x * blockDim.x + threadIdx.x;

    if (linha >= nIncognitas)
        return;

    data_t multiplicador = matriz(dA, linha, passo - 1, nIncognitas) / matriz(dA, passo - 1, passo - 1, nIncognitas);

    for (int coluna = passo - 1; coluna < nIncognitas; coluna++){
        matriz(dA, linha, coluna, nIncognitas) -= matriz(dA, passo - 1, coluna, nIncognitas) * multiplicador;
    }

    dB[linha] -= dB[passo - 1] * multiplicador;
}

void processaVetoresGPU(
    data_t *hmA,
    data_t *hvB,
    int nIncognitas)
{
    data_t *dA;
    data_t *dB;

    size_t sizeA =
        sizeof(data_t) *
        nIncognitas *
        nIncognitas;

    size_t sizeB =
        sizeof(data_t) *
        nIncognitas;

    cudaMalloc((void**)&dA, sizeA);
    cudaMalloc((void**)&dB, sizeB);

    cudaMemcpy(
        dA,
        hmA,
        sizeA,
        cudaMemcpyHostToDevice);

    cudaMemcpy(
        dB,
        hvB,
        sizeB,
        cudaMemcpyHostToDevice);

    for(int passo = 1;
        passo < nIncognitas;
        passo++)
    {
        int linhasRestantes =
            nIncognitas - passo;

        int blocks =
            (linhasRestantes +
             threadsPerBlock - 1)
            / threadsPerBlock;

        eliminaPassoKernel<<<
            blocks,
            threadsPerBlock>>>(
                dA,
                dB,
                nIncognitas,
                passo);

        cudaDeviceSynchronize();
    }

    cudaMemcpy(
        hmA,
        dA,
        sizeA,
        cudaMemcpyDeviceToHost);

    cudaMemcpy(
        hvB,
        dB,
        sizeB,
        cudaMemcpyDeviceToHost);

    cudaFree(dA);
    cudaFree(dB);
}