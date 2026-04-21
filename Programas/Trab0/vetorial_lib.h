/**
 * @file vetorial_lib.h
 * @brief Códigos de erro e protótipo da biblioteca de eliminação vetorial AVX/FMA.
 */

#ifndef VETORIAL_LIB_H
#define VETORIAL_LIB_H

/**
 * @defgroup ErrosCodigos Códigos de erro de processaVetores
 * @{
 */
#define ERR_OK               0  ///< Execução bem-sucedida
#define ERR_NULL_POINTER    -1  ///< Ponteiro nulo passado para mA ou vB
#define ERR_INVALID_SIZE    -2  ///< nIncognitas <= 0
#define ERR_SINGULAR_MATRIX -3  ///< Pivô nulo detectado (matriz singular)
/** @} */

/**
 * @brief Realiza eliminação de Gauss em Ax = b usando instruções AVX/FMA.
 *
 * @param mA          Ponteiro para a matriz A (n x n), row-major.
 * @param vB          Ponteiro para o vetor b de tamanho n.
 * @param nIncognitas Número de incógnitas, deve ser > 0.
 * @return Código de erro (ERR_OK em caso de sucesso).
 */
int processaVetores(double *mA, double *vB, int nIncognitas);

#endif
