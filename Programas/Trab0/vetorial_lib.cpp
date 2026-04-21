/**
 * @file vetorial_lib.cpp
 * @brief Implementação vetorizada (AVX/FMA) da eliminação Gaussiana.
 *
 * Este módulo implementa a etapa de eliminação Gaussiana para resolver um sistema
 * de equações lineares no formato Ax = b, transformando A em forma triangular
 * superior e atualizando b de acordo.
 *
 * Para cada pivô k:
 *   - Calcula o fator f = A[i][k] / A[k][k] para cada linha i > k
 *   - Aplica A[i] -= f * A[k] e b[i] -= f * b[k]
 *
 * Otimização SIMD:
 *   - AVX (256 bits): processa 4 doubles simultaneamente por iteração
 *   - FMA: combina multiplicação e subtração em uma única instrução
 *   - Epilogo escalar trata os elementos restantes quando n não é múltiplo de 4
 */

#include <immintrin.h>
#include <stddef.h>
#include "vetorial_lib.h"

/**
 * @brief Realiza eliminação de Gauss no sistema Ax = b usando instruções AVX/FMA.
 *
 * Para cada pivô k, calcula f = A[i][k]/A[k][k] e aplica a transformação:
 *   A[i][j] -= f * A[k][j]  (vetorizado em blocos de 4 doubles via AVX)
 *   b[i]    -= f * b[k]     (escalar)
 *
 * Após a transformação, A[i][k] é zerado explicitamente para estabilidade
 * numérica, evitando acúmulo de erros de ponto flutuante.
 *
 * @param mA          Ponteiro para a matriz A (n x n) em row-major. Não pode ser NULL.
 * @param vB          Ponteiro para o vetor b de tamanho n. Não pode ser NULL.
 * @param nIncognitas Número de incógnitas (dimensão do sistema). Deve ser > 0.
 *
 * @retval ERR_OK               Execução bem-sucedida.
 * @retval ERR_NULL_POINTER     mA ou vB é NULL.
 * @retval ERR_INVALID_SIZE     nIncognitas <= 0.
 * @retval ERR_SINGULAR_MATRIX  Pivô nulo detectado; a matriz é singular.
 */
int processaVetores(double *mA, double *vB, int nIncognitas) {
    if (mA == NULL || vB == NULL)
        return ERR_NULL_POINTER;
    if (nIncognitas <= 0)
        return ERR_INVALID_SIZE;

    for (int k = 0; k < nIncognitas; k++) {
        double pivot = mA[k * nIncognitas + k];

        if (pivot == 0.0)
            return ERR_SINGULAR_MATRIX;

        for (int i = k + 1; i < nIncognitas; i++) {
            double factor = mA[i * nIncognitas + k] / pivot;
            __m256d vfactor = _mm256_set1_pd(factor);

            int j = k;

            /* Loop vetorizado: processa 4 doubles por iteração com FMA */
            for (; j <= nIncognitas - 4; j += 4) {
                __m256d row_i = _mm256_loadu_pd(&mA[i * nIncognitas + j]);
                __m256d row_k = _mm256_loadu_pd(&mA[k * nIncognitas + j]);
                row_i = _mm256_fnmadd_pd(vfactor, row_k, row_i);
                _mm256_storeu_pd(&mA[i * nIncognitas + j], row_i);
            }

            /* Epilogo escalar para os elementos restantes */
            for (; j < nIncognitas; j++) {
                mA[i * nIncognitas + j] -= factor * mA[k * nIncognitas + j];
            }

            vB[i] -= factor * vB[k];

            /* Zeragem explícita para evitar acúmulo de erro numérico */
            mA[i * nIncognitas + k] = 0.0;
        }
    }
    return ERR_OK;
}