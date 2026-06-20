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


/**
 * @brief Executa a eliminação gaussiana utilizando múltiplas threads no host.
 *
 * Para cada passo da eliminação, as linhas abaixo do pivô são distribuídas entre as threads disponíveis.
 *
 * @param hmA Matriz A.
 * @param hvB Vetor B.
 * @param nIncognitas Número de incógnitas do sistema.
 */
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

            int rc = pthread_create(&threads[t], NULL, threadFunc, &args[t]);

            if(rc != 0) {
                fprintf(stderr,"[ERROR 1] Falha ao criar thread %d\n", t);
                exit(EXIT_FAILURE);
            }
        }

        for(int t = 0; t < nThreads; t++) {
            int rc = pthread_join(threads[t],(void **)&ret);

            if(rc != 0) {
                fprintf(stderr, "[ERROR 2] Falha no join de threads %d\n",t);
                exit(EXIT_FAILURE);
            }
            free(ret);
        }

    }
}


/**
 * @brief Kernel CUDA responsável pela eliminação de linhas para um determinado passo do método de Gauss.
 *
 * Cada thread CUDA processa uma linha da matriz localizada abaixo da linha pivô.
 *
 * @param dA Matriz A armazenada na memória da GPU.
 * @param dB Vetor B armazenado na memória da GPU.
 * @param nIncognitas Número de incógnitas do sistema.
 * @param passo Passo atual da eliminação gaussiana.
 */
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


/**
 * @brief Executa a eliminação gaussiana utilizando CUDA.
 *
 * A matriz e o vetor são copiados para a memória da GPU, processados por meio de vários lançamentos de kernel e depois copiados de volta para a memória principal.
 *
 * @param hmA Matriz A.
 * @param hvB Vetor B.
 * @param nIncognitas Número de incógnitas do sistema.
 */
void processaVetoresGPU(data_t *hmA, data_t *hvB, int nIncognitas) {
    data_t *dA;
    data_t *dB;

    size_t sizeA = sizeof(data_t) * nIncognitas *nIncognitas;
    size_t sizeB = sizeof(data_t) * nIncognitas;

    cudaError_t err;

    err = cudaMalloc((void**)&dA, sizeA);
    if(err != cudaSuccess) {
        fprintf(stderr, "[ERROR 3] cudaMalloc dA: %s\n", cudaGetErrorString(err));
        cudaFree(dA);
        return;
    }
    err = cudaMalloc((void**)&dB, sizeB);
    if(err != cudaSuccess) {
        fprintf(stderr, "[ERROR 4] cudaMalloc dB: %s\n", cudaGetErrorString(err));
        cudaFree(dB);
        return;
    }

    err = cudaMemcpy(dA, hmA, sizeA, cudaMemcpyHostToDevice);
    if(err != cudaSuccess) {
        fprintf(stderr, "[ERROR 5] cudaMemcpy matriz H->D falhou: %s\n", cudaGetErrorString(err));
        return;
    }
    err = cudaMemcpy(dB, hvB, sizeB, cudaMemcpyHostToDevice);
    if(err != cudaSuccess) {
        fprintf(stderr, "[ERROR 6] cudaMemcpy vetor H->D falhou: %s\n", cudaGetErrorString(err));
        return;
    }

    for(int passo = 1; passo < nIncognitas; passo++) {
        int linhasRestantes = nIncognitas - passo;
        int blocks = (linhasRestantes + threadsPerBlock - 1) / threadsPerBlock;

        eliminaPassoKernel<<< blocks, threadsPerBlock>>>(dA, dB, nIncognitas,passo);
        err = cudaGetLastError();

        if(err != cudaSuccess) {
            fprintf(stderr, "[ERROR 7] Falha ao lançar o kernel: %s\n", cudaGetErrorString(err));
            return;
        }
        err = cudaDeviceSynchronize();

        if(err != cudaSuccess) {
            fprintf(stderr, "[ERROR 8] Falha ao sincronizar device: %s\n", cudaGetErrorString(err));
            return;
        }
    }

    err = cudaMemcpy(hmA, dA, sizeA, cudaMemcpyDeviceToHost);
    if(err != cudaSuccess) {
        fprintf(stderr, "[ERROR 9] cudaMemcpy matriz D->H falhou: %s\n", cudaGetErrorString(err));
        return;
    }
    err = cudaMemcpy(hvB, dB, sizeB, cudaMemcpyDeviceToHost);
    if(err != cudaSuccess) {
        fprintf(stderr, "[ERROR 10] cudaMemcpy vetor D->H falhou: %s\n", cudaGetErrorString(err));
        return;
    }


    cudaFree(dA);
    cudaFree(dB);
}