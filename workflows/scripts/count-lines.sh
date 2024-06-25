#!/bin/bash

# Run cloc to count lines of code and save the result to lines_of_code.txt
cloc --by-file --csv --out=lines_of_code.csv .

# Convert CSV to readable text format
echo "Lines of Code Summary:" > lines_of_code.txt
echo "" >> lines_of_code.txt
cloc . >> lines_of_code.txt

echo "" >> lines_of_code.txt
echo "Detailed Report (CSV Format):" >> lines_of_code.txt
cat lines_of_code.csv >> lines_of_code.txt

# Clean up intermediate CSV file
rm lines_of_code.csv
