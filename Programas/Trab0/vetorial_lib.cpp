#include <immintrin.h>
#include <stddef.h>

/**
 * @file vetorial_lib.cpp
 *
 * Esse módulo implementa a etapa de eliminação Gaussiana para resolver um sistema de equações lineares no formato Ax = b.
 * Isso é feito transformando a matriz A em uma matriz triangular superior e alterando o vetor b para refletir.
 * Para cada coluna pivot k:
 *    - Calcule o fator para cada coluna i > k
 *    - Subtraia um multiplo da coluna pivot na coluna i
 *    - Atualize a matriz A e o vetor b
 *
 * A implementação usa AVX e FMA para acelerar operações.
 * 
 * Otimização SIMD:
 *    - Usa AVX (registradores de 256 bits) para processar 4 valores tipo double simultaneamente
 *    - Usa FMA para combinar operações de multiplicação e subtração.
 */

/**
 * @brief Realiza eliminação no sistema linear Ax = b.
 *
 * @param mA Ponteiro para a matriz A (n x n)
 * @param vB Ponteiro para o vetor b (n)
 * @param nIncognitas Numero de incognitas (dimensão do sistema)
 */

void processaVetores(double *mA, double *vB, int nIncognitas) {
    for (int k = 0; k < nIncognitas; k++) {
        double pivot = mA[k * nIncognitas + k];

        for (int i = k + 1; i < nIncognitas; i++) {
            double factor = mA[i * nIncognitas + k] / pivot;

            __m256d vfactor = _mm256_set1_pd(factor);

            int j = k;

            /**
             * @brief loop vetorizado
             *
             * Processa 4 elementos por vez usando registradores AVX
             */
            for (; j <= nIncognitas - 4; j += 4) {
                __m256d row_i = _mm256_loadu_pd(&mA[i * nIncognitas + j]);
                __m256d row_k = _mm256_loadu_pd(&mA[k * nIncognitas + j]);

                // FMA: row_i = row_i - factor * row_k
                row_i = _mm256_fnmadd_pd(vfactor, row_k, row_i);

                _mm256_storeu_pd(&mA[i * nIncognitas + j], row_i);
            }

            /**
             * @brief loop escalar do que restou
             *
             * Lida com elementos restantes quando n não é múltiplo de 4
             */
            for (; j < nIncognitas; j++) {
                mA[i * nIncognitas + j] -= factor * mA[k * nIncognitas + j];
            }

            // atualiza o vetor b
            vB[i] -= factor * vB[k];

            // para estabilidade numérica
            mA[i * nIncognitas + k] = 0.0;
        }
    }
}
