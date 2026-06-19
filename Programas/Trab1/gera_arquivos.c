#include <stdio.h>
#include <stdlib.h>

#define N 2048

int main() {
    FILE *fA = fopen("matrizA.bin", "wb");
    FILE *fB = fopen("vetorB.bin", "wb");

    float *A = malloc(sizeof(float) * N * N);
    float *B = malloc(sizeof(float) * N);

    if (!A || !B) {
        printf("Allocation failed\n");
        return 1;
    }

    for(int i = 0; i < N; i++)
    {
        B[i] = i + 1;

        for(int j = 0; j < N; j++)
        {
            A[i * N + j] = ((i + j) % 10) + 1;

            if(i == j)
                A[i * N + j] += N;
        }
    }

    fwrite(A, sizeof(float), N * N, fA);
    fwrite(B, sizeof(float), N, fB);

    free(A);
    free(B);

    printf("Generated %dx%d matrix\n", N, N);

    return 0;
}