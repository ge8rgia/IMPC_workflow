#!/bin/bash

# Create formatted_csvs directory if it doesn't exist
mkdir -p formatted_csvs

# Read master headers and create header row (convert to lowercase for case-insensitive matching)
printf "Retrieving headers..."
HEADER_STRING=$(grep -h "^" data/*.csv | awk -F',' '$1 != "" {print tolower($1)}' | sort -u | tr '\n' ',' | sed 's/,$//')
printf "\rHeaders: %s\n" "$HEADER_STRING"

# Convert comma-separated string to array
IFS=',' read -ra HEADER_LIST <<< "$HEADER_STRING"

NUM_OF_CSV_FILES=$(ls data/*.csv | wc -l | xargs)
printf "\rProgress: 0/%s" "$NUM_OF_CSV_FILES"

# Initialize count array for each header
declare -a header_counts
for i in "${!HEADER_LIST[@]}"; do
    header_counts[$i]=0
done

x=0
# Process each CSV file in the current directory
for csv_file in data/*.csv; do
    x=$((x+1))
    # Build output row in the order specified by HEADER_LIST
    output_values=()
    header_idx=0
    for header in "${HEADER_LIST[@]}"; do
        # Extract value for this header from the CSV file (case-insensitive matching)
        # Use awk to extract everything after the first comma, handling any order and case differences
        value=$(awk -F',' -v h="$header" 'tolower($1) == h {print $2}' "$csv_file" | xargs)
        output_values+=("${value}")
        
        # Count if value is not empty
        if [ -n "$value" ]; then
            header_counts[$header_idx]=$((${header_counts[$header_idx]} + 1))
        fi
        header_idx=$((header_idx + 1))
    done
    
    # Create output file with reformatted data
    output_file="formatted_csvs/$(basename "$csv_file")"
    echo "$HEADER_STRING" > "$output_file"
    
    # Build output row with comma-separated values
    output_row=""
    for i in "${!output_values[@]}"; do
        if [ $i -eq 0 ]; then
            output_row="${output_values[$i]}"
        else
            output_row="${output_row},${output_values[$i]}"
        fi
    done
    echo "$output_row" >> "$output_file"
    printf "\rProgress: %s/%s" "$x" "$NUM_OF_CSV_FILES"
done
printf "\n"

# Print count of each column that had a value
count_row=""
for i in "${!header_counts[@]}"; do
    if [ $i -eq 0 ]; then
        count_row="${header_counts[$i]}"
    else
        count_row="${count_row},${header_counts[$i]}"
    fi
done
echo "$HEADER_STRING"
echo "$count_row"
echo "Done!"

