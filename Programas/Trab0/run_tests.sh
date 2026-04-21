

set -e

RESULTADO="resultados.csv"
SIZES="8 16 32 64 128 256 512 1024 2048 4096"

echo "=== Compilando executáveis ==="

gcc -O2 -Wall -o geraDados geraDados.cpp
echo "  [OK] geraDados"

gcc -O2 -Wall -o equacao_escalar equation_test.cpp escalar_lib.cpp comum.cpp
echo "  [OK] equacao_escalar"

gcc -O2 -mavx2 -mfma -Wall -o equacao_vetorial equation_test.cpp vetorial_lib.cpp comum.cpp
echo "  [OK] equacao_vetorial"

echo ""
echo "=== Iniciando testes ==="
echo "N,escalar_ms,vetorial_ms,speedup" > "$RESULTADO"

for N in $SIZES; do
    echo -n "  N=$N ... "

    #
    ./geraDados "$N" 2>/dev/null

    
    SAIDA_ESC=$(./equacao_escalar -n "$N" -m Matriz_A.bin -v Vetor_B.bin 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "ERRO na versão escalar para N=$N"
        continue
    fi
    T_ESC=$(echo "$SAIDA_ESC" | grep "Tempo do cálculo" | awk '{print $4}')

  
    SAIDA_VET=$(./equacao_vetorial -n "$N" -m Matriz_A.bin -v Vetor_B.bin 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "ERRO na versão vetorial para N=$N"
        continue
    fi
    T_VET=$(echo "$SAIDA_VET" | grep "Tempo do cálculo" | awk '{print $4}')

   
    SPEEDUP=$(awk "BEGIN {if ($T_VET > 0) printf \"%.4f\", $T_ESC/$T_VET; else print \"inf\"}")

    echo "$N,$T_ESC,$T_VET,$SPEEDUP" >> "$RESULTADO"
    echo "escalar=${T_ESC}ms  vetorial=${T_VET}ms  speedup=${SPEEDUP}x"
done

echo ""
echo "=== Resultados salvos em $RESULTADO ==="
echo ""
cat "$RESULTADO"


rm -f Matriz_A.bin Vetor_B.bin tempos.csv
