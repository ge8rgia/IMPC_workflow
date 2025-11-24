#!/bin/bash
#Setup
INPUT_DIR="formatted_csvs"
OUTPUT_DIR="processed_data"
OUTPUT_FILE="$OUTPUT_DIR/merged_output.csv"

mkdir -p "$OUTPUT_DIR"
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: $INPUT_DIR folder not found"
    exit 1
fi

NUM_OF_CSV_FILES=$(find "$INPUT_DIR" -maxdepth 1 -name '*.csv'| wc -l ) #Counts files in format_csv folder

if [ "$NUM_OF_CSV_FILES" -eq 0 ]; then
    echo "Error: No csv files found in $INPUT_DIR folder" #exits the script if no csv files present 
    exit 1
fi

printf "Merging %d CSV files ...\n" "$NUM_OF_CSV_FILES" #displays the progress message


#EXPLANATION OF MERGE 
#Awk: processes all the formatted files in one stream
#fnr records the line number in current processing file
#nr is the total record line number for all files in the formatted_csv directory

#1st condition if they both equate to 1, is the true first line of the file (header) and prints once
#2nd condition says if FNR is true (all lines exceppt the first line of every file)
#prints all data rows automatically and skips all the headers

awk 'NF > 0 && FNR == 1 && NR ==1 {print}  NF >0 && FNR > 1 {print}' "$INPUT_DIR"/*.csv > "$OUTPUT_FILE"

printf "Done\n"
echo "Merged files saved to $OUTPUT_FILE" #Sucess message 
