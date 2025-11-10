#!/bin/bash

#Pitfall contingency
set -e
set -o pipefail #1st line makes script exit if any command below fails, whilst pipefail means
                #if any part of a pipeline (includes command including "|") the pipe stops

#Setup
INPUT_DIR="data"
OUTPUT_DIR="formatted_csvs"

mkdir -p "$OUTPUT_DIR" # Create formatted_csvs directory if not present 


#Checks if the input directory exists before executing 
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory '$INPUT_DIR' not found." >&2
    exit 1
fi

#Parralel head gathering process
printf "Retrieving headers (in parallel)...\n" #Parralel head gathering process

CPU_CORES=8 #Manually set to using 8 CPU Cores for parralel tasks

# Use find, xargs, and awk to do this in parallel, using the set number of cores
HEADER_STRING=$(find "$INPUT_DIR/" -name "*.csv" -print0 | \
xargs -0 -P "$CPU_CORES" -n 100 awk -F',' '$1 != "" {print tolower($1)}' | \
sort -u | tr '\n' ',' | sed 's/,$//')

if [ -z "$HEADER_STRING" ]; then
    echo "Error: No headers found in $INPUT_DIR. Check directory or file contents." >&2
    exit 1
fi          #Checks if any headers exist to begin with if not, exists the process

printf "Headers retrieved! Found %s unique headers.\n" "$(echo "$HEADER_STRING" | tr ',' '\n' | wc -l)"

#%s: string placeholder, 'tr': comma converter to new lines, for pipe to count (wc -l)


NUM_OF_CSV_FILES=$(ls "$INPUT_DIR"/*.csv | wc -l | xargs)  #counts csv files in data dir,
                                                           #xarg trims the white space
printf "Progress: 0/%s" "$NUM_OF_CSV_FILES" #gives user initial merge progress 

x=0
# Process each CSV file in the current directory
for csv_file in "$INPUT_DIR"/*.csv; do
    x=$((x+1)) #Incriment file counter 
    output_file="$OUTPUT_DIR/$(basename "$csv_file")"

    
    echo "$HEADER_STRING" > "$output_file" #Writes main header to the outputfile 

    #  Runs once per command,makes columns to headers 
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
            data[tolower($1)] = value #Stores lowercase keys, to allow for case-insensitive matching
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

    printf "\rProgress: %s/%s" "$x" "$NUM_OF_CSV_FILES" #Updates progress counter as script runs 
done

printf "\n"
echo "Done! Reformatted files are in $OUTPUT_DIR" #Success message 
