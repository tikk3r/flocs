MARCH=$(gcc -march=native -Q --help=target | grep '\-march=  ' | awk -F" " '{print $2}')
MTUNE=$(gcc -march=native -Q --help=target | grep '\-mtune=  ' | awk -F" " '{print $2}')

echo Use \"-march=$MARCH -mtune=$MTUNE\" flags for native compilation.
