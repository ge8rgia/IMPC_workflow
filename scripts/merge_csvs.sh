#!/bin/bash

# Output file for merged CSV
OUTPUT_FILE="merged_output.csv"

# Check if formatted_csvs directory exists
if [ ! -d "formatted_csvs" ]; then
    echo "Error: formatted_csvs directory not found!"
    exit 1
fi

# Count CSV files
NUM_OF_CSV_FILES=$(ls formatted_csvs/*.csv 2>/dev/null | wc -l | xargs)

if [ "$NUM_OF_CSV_FILES" -eq 0 ]; then
    echo "Error: No CSV files found in formatted_csvs directory!"
    exit 1
fi

printf "Merging %s CSV files..." "$NUM_OF_CSV_FILES"

# Flag to track if we've written the header
header_written=false
file_count=0

# Process each CSV file in formatted_csvs directory
for csv_file in formatted_csvs/*.csv; do
    # Skip if no CSV files found
    [ -f "$csv_file" ] || continue
    
    file_count=$((file_count + 1))
    
    # Read the file line by line
    line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        
        # First line is the header
        if [ $line_num -eq 1 ]; then
            if [ "$header_written" = false ]; then
                # Write header only once
                echo "$line" > "$OUTPUT_FILE"
                header_written=true
            fi
        else
            # Skip empty lines
            [ -z "$line" ] && continue
            
            # Append data rows
            echo "$line" >> "$OUTPUT_FILE"
        fi
    done < "$csv_file"
    
    printf "\rMerging: %s/%s" "$file_count" "$NUM_OF_CSV_FILES"
done

printf "\n"
echo "Merged CSV saved to: $OUTPUT_FILE"
echo "Done!"

