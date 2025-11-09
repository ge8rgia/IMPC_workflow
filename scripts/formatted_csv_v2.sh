#!/bin/bash

#Setup
INPUT_DIR="data"
OUTPUT_DIR="formatted_csvs"

mkdir -p "$OUTPUT_DIR" # Create formatted_csvs directory if not present 

printf "Retrieving headers (in parallel)...\n" #Parralel head gathering process

CPU_CORES=8 #Manually set to using 8 CPU Cores for parralel tasks

# Use find, xargs, and awk to do this in parallel, using the set number of cores
HEADER_STRING=$(find "$INPUT_DIR/" -name "*.csv" -print0 | \
xargs -0 -P "$CPU_CORES" -n 100 awk -F',' '$1 != "" {print tolower($1)}' | \
sort -u | tr '\n' ',' | sed 's/,$//')

printf "Headers retrieved! Found %s unique headers.\n" "$(echo "$HEADER_STRING" | tr ',' '\n' | wc -l)"

NUM_OF_CSV_FILES=$(ls "$INPUT_DIR"/*.csv | wc -l | xargs)
printf "Progress: 0/%s" "$NUM_OF_CSV_FILES" #Runs awk once per file 

x=0
# Process each CSV file in the current directory
for csv_file in "$INPUT_DIR"/*.csv; do
    x=$((x+1))
    output_file="$OUTPUT_DIR/$(basename "$csv_file")"

    # Write the master header string to the new file
    echo "$HEADER_STRING" > "$output_file"

    #  This is the new, fast awk command
     awk -F',' -v headers="$HEADER_STRING" '  # We run awk ONCE per file.
    BEGIN {
        split(headers, header_array, ",")  # Split the master header list into an awk array

        header_count = length(header_array) # Get length of header array
    }

    # Read every line of the file and store its key-value pair to memory
    {
        # Store value, key is lowercase parameter name, skip empty
        if ($1 != "") {

            value = $2            # Combine all fields after the first, in case value has a comma
            for (i=3; i<=NF; i++) {
                value = value "," $i
            }
            data[tolower($1)] = value
        }
    }
    # Runs once after the whole file is read
    END {

        for (i = 1; i <= header_count; i++) { # Loop function to go through the headers IN ORDER
            header = header_array[i]

            value = data[header]  # Get the value from our data array

            printf "%s", value # Print the value. If it was empty, this prints nothing.
            if (i < header_count) {
                printf "," # Add a comma, but not for the last item.
            }
        }

        printf "\n"  # Print a final newline for the row
    }
    ' "$csv_file" >> "$output_file" # Awk reads the file and appends its output

    printf "\rProgress: %s/%s" "$x" "$NUM_OF_CSV_FILES"
done

printf "\n"
echo "Done! Reformatted files are in $OUTPUT_DIR"
