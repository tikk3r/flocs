MS=$1
RESULT=$(python -c "import casacore.tables as ct; ct.table(\"$MS\")" 2>/dev/null)
if ! grep -q "Successful readonly open" <<< "$RESULT"; then
    echo "$MS is NOT a valid MeasurementSet."
fi
