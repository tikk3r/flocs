MARCH=$(gcc -march=native -Q --help=target | grep '\-march=  ' | awk -F" " '{print $2}')
MTUNE=$(gcc -march=native -Q --help=target | grep '\-mtune=  ' | awk -F" " '{print $2}')

echo Use \"-march=$MARCH -mtune=$MTUNE\" flags for native compilation.

AVX512=$(gcc -march=$MARCH -mtune=$MTUNE -dM -E - < /dev/null | egrep "AVX512")
if [[ $AVX512 == *"AVX512"* ]]; then
    echo -march=$MARCH -mtune=$MTUNE supports AVX512
else
    echo -march=$MARCH -mtune=$MTUNE does _NOT_ support AVX512
fi
