#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    int N = atoi(argv[1]);
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
        for(int j = 0; j < N; j++)
        {
            if(i == j)
                A[i * N + j] = (float)(N + 1);
            else
                A[i * N + j] = 1.0f;
        }

        B[i] = (float)(i + 1);
    }

    fwrite(A, sizeof(float), N * N, fA);
    fwrite(B, sizeof(float), N, fB);

    fclose(fA);
    fclose(fB);

    free(A);
    free(B);

    printf("Generated %dx%d matrix\n", N, N);

    return 0;
}