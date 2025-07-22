echo "=============================="
echo "=== BBS skymodel rescaler  ==="
echo "=== Author: Frits Sweijen  ==="
echo "=============================="
echo "If you think you've found a bug, report it at https://github.com/tikk3r/flocs/issues"
echo
if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo "Usage:"
    echo "$(basename $0) <skymodel file> <flux scaling factor> <spectral index terms>"
    echo "Example: rescale_skymodel.sh myskymodel.txt 0.86 -0.8,0.2"
    exit 0
fi

echo "Rescaling Stokes I by a factor of $2"
echo "Overwriting spectral indices with [$3]"

awk -F, -v OFS=',' -v factor=$2 -v new_si="[$3]" '
NR == 1 {
    print $0; next
}
{
    $5 = $5 * factor
    $6 = new_si
    print
}
' $1 > "$(basename $1)_rescaled.txt"
