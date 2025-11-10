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

CPU_CORES=8 #Manually set to using 8 CPU Cores for parralel tasks, ideal for HPC set to 2-4 for local

# Use find, xargs, and awk to do this in parallel, using the set number of cores
HEADER_STRING=$(find "$INPUT_DIR/" -maxdepth 1 -name "*.csv" -print0 | \
xargs -0 -P "$CPU_CORES" -n 100 awk -F',' '$1 != "" {print tolower($1)}' | \
sort -u | tr '\n' ',' | sed 's/,$//')

if [ -z "$HEADER_STRING" ]; then
    echo "Error: No headers found in $INPUT_DIR. Check directory or file contents." >&2
    exit 1
fi          #Checks if any headers exist to begin with if not, exists the process

printf "Headers retrieved, Found %s unique headers.\n" "$(echo "$HEADER_STRING" | tr ',' '\n' | wc -l)"

#%s: string placeholder, 'tr': comma converter to new lines, for pipe to count (wc -l)

#Parralel file processing
NUM_OF_CSV_FILES=$(find "$INPUT_DIR" -maxdepth 1 -name "*.csv" | wc -l) #gets file counts
printf "Progressing %s in parralel ...\n" "$NUM_OF_CSV_FILES" #gives user start message  

x=0
# Process each CSV file in the current directory via a function
process_file() {
    csv_file="$1" # The file path is the first argument
    output_file="$OUTPUT_DIR/$(basename "$csv_file")"

     echo "$HEADER_STRING" > "$output_file" #writes main header to output file

#sets input field seperator to comma, splits the header strings into array before storing in
      #header count    
     awk -F',' -v headers="$HEADER_STRING" '
    BEGIN {
        split(headers, header_array, ",")
        header_count = length(header_array)
    }
#Reads every line in file and commits  key-value pair to memory 
    {
#Get the entire value by finding the first comma and taking the rest of the line 
        if ($1 != "") {
            # Find the position of the first comma (used as field separator)
            first_comma_pos = index($0, ",")
#value is rest of line after first comma, if comma is found string starts from character after comma
            if (first_comma_pos > 0) {
                value = substr($0, first_comma_pos + 1) 
            } else {
                value = "" # Should not happen in key,value format, but safety mechanism
            }

            data[tolower($1)] = value   #Store value with lowercase key for case-insensitive matching
        } 
#Runs once after the whole file is read 
    END {
        for (i = 1; i <= header_count; i++) { # Loop function to go through the headers IN ORDER
            header = header_array[i]

            value = data[header]  # Get the value from our data array

            printf "%s", value # Print the value. If it was empty, this prints nothing.
            if (i < header_count) {
                printf "," # Add comma as seperator, but not for last item avoiding trailing comma
            }
        }

        printf "\n"  # Print a final newline for the row
    }
    ' "$csv_file" >> "$output_file" # Awk reads the file and appends its output

}
#Export function and the variables its made to run xarg
export -f process_file
export HEADER_STRING OUTPUT_DIR

#parallel task uses , xarg removes white spaces
find "$INPUT_DIR" -maxdepth 1 -name "*.csv" -print0 \   # emit NUL-delimited paths, avoids subdir
| xargs -0 -P "$CPU_CORES" \                             # read NUL paths to let  run in parallel
    bash -c 'process_file "$@"' _                        #bash wrapper lets $0 becomes _, files in "$@"



echo "Done! Reformatted files are in $OUTPUT_DIR" #Success message 
