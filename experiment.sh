#!/bin/bash

# Define the workload file and the log file
WORKLOAD_FILE="./workloads/workloada"
LOG_FILE="./ycsb_results.log"
OUTPUT_CSV="./analysis/output.csv"

# Define input and output filenames
INPUT_FILE="./analysis/output.csv"
OUTPUT_FILE="./analysis/all_experiments.csv"

# Experiment parameters
run="9"

# Normal experiment parameters
extendproportion_normal="0"
readproportion_normal="0.5"
updateproportion_normal="0.5"
scanproportion_normal="0"
insertproportion_normal="0"

# Extend phase experiment parameters
extendproportion_extend="1"
readproportion_extend="0"
updateproportion_extend="0"
scanproportion_extend="0"
insertproportion_extend="0"

# After extend phase experiment parameters
extendproportion_postextend="0"
readproportion_postextend="0.5"
updateproportion_postextend="0.5"
scanproportion_postextend="0"
insertproportion_postextend="0"

# Function to log and print messages
log() {
    echo "$1" | tee -a $LOG_FILE
}

# Clear the log file
> $LOG_FILE

# Function to write results as a csv 
write_result() {
    local first="$1"

    # Remove rows not starting with specific operations and filter specific operations
    filtered_output=$(awk '/^\[(INSERT|READ|UPDATE|SCAN|EXTEND)\]/' "$INPUT_FILE")

    if [ "$first" == "TRUE" ]; then   
        # Extract unique second values (except the first one) and create header
        header="Run,Phase,Recordcount,Readallfields,Requestdist,Operation,Readprop,Updateprop,Scanprop,Insertprop,Extendprop,$(awk '{print $2}' <<< "$filtered_output" | sed 's/,$//' | uniq | awk '{ORS=","; print}')"
        echo "$header" > "$OUTPUT_FILE"
    fi

    # Iterate through each line
    values=""
    k=1
    prev_operation=""
    while IFS= read -r line; do
        # Extract operation and third value
        operation=$(echo "$line" | awk '{print $1}' | sed 's/,$//' | tr -d '[]')
        third_value=$(echo "$line" | awk '{print $3}' | sed 's/,$//')
        # Append to the values variable
        if [ $k -eq 1 ]; then
            values="$run,$phase,$recordcount,$readallfields,$requestdistribution,$operation,$readproportion,$updateproportion,$scanproportion,$insertproportion,$extendproportion,$third_value"
            k=$((k+1))
            prev_operation="$operation"
        else
            values="$values,$third_value"
        fi
        if [ "$prev_operation" != "$operation" ]; then
            # Print the values to the output file
            echo "$values" >> "$OUTPUT_FILE"
            values="$run,$phase,$recordcount,$readallfields,$requestdistribution,$operation,$readproportion,$updateproportion,$scanproportion,$insertproportion,$extendproportion,$third_value"
            prev_operation="$operation"
        fi
    done <<< "$filtered_output"

    # Print the values to the output file
    echo "$values" >> "$OUTPUT_FILE"

    # Print completion message
    echo "Arrangement completed. Output saved to $OUTPUT_FILE"
}


# Step 0: Delete the ycsb database on MongoDB if any
log "=== Deleting the ycsb database on MongoDB, if any ==="
#mongo ycsb --eval "db.dropDatabase()" | tee -a $LOG_FILE
mongosh 
#use ycsb | tee -a $LOG_FILE
#db.runCommand( { dropDatabase: 1 } ) | tee -a $LOG_FILE

# Step 1: Set extendproportion to 0
log "=== Setting extendproportion to 0 ==="
perl -i -p -e "s/^extendproportion=.*/extendproportion=$extendproportion_normal/" "$WORKLOAD_FILE"
perl -i -p -e "s/^readproportion=.*/readproportion=$readproportion_normal/" $WORKLOAD_FILE
perl -i -p -e "s/^updateproportion=.*/updateproportion=$updateproportion_normal/" $WORKLOAD_FILE
perl -i -p -e "s/^scanproportion=.*/scanproportion=$scanproportion_normal/" $WORKLOAD_FILE
perl -i -p -e "s/^insertproportion=.*/insertproportion=$scanproportion_normal/" $WORKLOAD_FILE
source "$WORKLOAD_FILE"

# Step 2: Execute the load phase
log "=== Executing the load phase with extendproportion=0 ==="
phase="load"
./bin/ycsb.sh load mongodb -s -P $WORKLOAD_FILE > $OUTPUT_CSV
write_result "FALSE"

# Step 3: Execute the run phase
log "=== Executing the run phase with extendproportion=0 ==="
phase="run"
./bin/ycsb.sh run mongodb -s -P $WORKLOAD_FILE > $OUTPUT_CSV
write_result "FALSE"

# Step 4: Delete the ycsb database on MongoDB
log "=== Deleting the ycsb database on MongoDB ==="
mongosh 
#use ycsb | tee -a $LOG_FILE
#db.runCommand( { dropDatabase: 1 } ) | tee -a $LOG_FILE

# Step 5: Set extendproportion to 0.2 and other proportions to 0
log "=== Setting extendproportion to 0.2 and other proportions to 0 ==="
perl -i -p -e "s/^extendproportion=.*/extendproportion=$extendproportion_extend/" $WORKLOAD_FILE
perl -i -p -e "s/^readproportion=.*/readproportion=$readproportion_extend/" $WORKLOAD_FILE
perl -i -p -e "s/^updateproportion=.*/updateproportion=$updateproportion_extend/" $WORKLOAD_FILE
perl -i -p -e "s/^scanproportion=.*/scanproportion=$scanproportion_extend/" $WORKLOAD_FILE
perl -i -p -e "s/^insertproportion=.*/insertproportion=$insertproportion_extend/" $WORKLOAD_FILE
source "$WORKLOAD_FILE"

# Step 6: Execute the load phase
log "=== Executing the load phase with extendproportion=0.2 and other proportions=0 ==="
phase="load"
./bin/ycsb.sh load mongodb -s -P $WORKLOAD_FILE > $OUTPUT_CSV
write_result "FALSE"

# Step 7: Execute the run phase
log "=== Executing the run phase with extendproportion=0.2 and other proportions=0 ==="
phase="extend"
./bin/ycsb.sh run mongodb -s -P $WORKLOAD_FILE > $OUTPUT_CSV
write_result "FALSE"

# Step 8: Set extendproportion back to 0 and read/update proportions to 0.5
log "=== Setting extendproportion back to 0 and read/update proportions to 0.5 ==="
perl -i -p -e "s/^extendproportion=.*/extendproportion=$extendproportion_postextend/" $WORKLOAD_FILE
perl -i -p -e "s/^readproportion=.*/readproportion=$readproportion_postextend/" $WORKLOAD_FILE
perl -i -p -e "s/^updateproportion=.*/updateproportion=$updateproportion_postextend/" $WORKLOAD_FILE
perl -i -p -e "s/^scanproportion=.*/scanproportion=$scanproportion_postextend/" $WORKLOAD_FILE
perl -i -p -e "s/^insertproportion=.*/insertproportion=$insertproportion_postextend/" $WORKLOAD_FILE
source "$WORKLOAD_FILE"

# Step 9: Execute the run phase
log "=== Executing the run phase with extendproportion=0 and read/update proportions=0.5 ==="
phase="run"
./bin/ycsb.sh run mongodb -s -P $WORKLOAD_FILE > $OUTPUT_CSV
write_result "FALSE"

log "=== All steps completed. Results are logged in $LOG_FILE ==="
