#!/bin/bash

#sudo mongod --config /etc/mongod.conf &         # Start first instance on 27017
#sudo mongod --config /etc/mongod_28018.conf &   # Start second instance on 28018

YCSB="bin/ycsb.sh"
MONGOSHELL="/usr/bin/mongosh"
MONGODUMP="mongodump"
MONGORESTORE="mongorestore"

# Define the workload file and the log file
WORKLOAD_FILE="../workloads/workloada-extend"
LOG_FILE="./ycsb_results.log"
OUTPUT_CSV="../analysis/output.csv"

# Define input and output filenames
INPUT_FILE="../analysis/output.csv"
OUTPUT_FILE="../analysis/Data/Baseline_data/mongodb_run1_spreadrun_light.csv"

# DB names
DB_NAME="ycsb"

fieldlengthoriginal="100"
extendoperationcount="10000"

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
    overall_output=$(awk '/^\[(OVERALL)\]/' "$INPUT_FILE")

    if [ "$first" == "TRUE" ]; then   
        # Extract unique second values (except the first one) and create header
        header="Epoch,Phase,Recordcount,Readallfields,Requestdist,Operation,CPU,Memory,Readprop,Updateprop,Scanprop,Insertprop,Extendprop,Runtime(ms),Throughput(ops/sec),$(awk '{print $2}' <<< "$filtered_output" | sed 's/,$//' | uniq | awk '{ORS=","; print}')"
        echo "$header" > "$OUTPUT_FILE"
        return
    fi

    # Iterate through each line
    values_1=""
    values_2=""
    k=1
    p=1
    prev_operation=""
    while IFS= read -r line; do
        # Extract operation and third value
        operation=$(echo "$line" | awk '{print $1}' | sed 's/,$//' | tr -d '[]')
        third_value=$(echo "$line" | awk '{print $3}' | sed 's/,$//')
        r=$((10 * (epoch - 1) + run))

        run_specific=()
        # Extract throughput
        while IFS= read -r inner_line; do
            # Extract third value
            tmp=$(echo "$inner_line" | awk '{print $3}' | sed 's/,$//')
            run_specific+=("$tmp")
        done <<< "$overall_output"

        # Append to the values variable
        if [ $k -eq 1 ]; then
            values_1="$r,$phase,$recordcount,$readallfields,$requestdistribution,$operation,$cpu,$memory,$readproportion,$updateproportion,$scanproportion,$insertproportion,$extendproportion,${run_specific[0]},${run_specific[1]},$third_value"            
            k=$((k + 1))
            prev_operation="$operation"
        elif [ $p -eq 1 ] && [ "$prev_operation" == "$operation" ]; then
            values_1="$values_1,$third_value"
        elif [ $p -eq 1 ] && [ "$prev_operation" != "$operation" ]; then
            values_2="$r,$phase,$recordcount,$readallfields,$requestdistribution,$operation,$cpu,$memory,$readproportion,$updateproportion,$scanproportion,$insertproportion,$extendproportion,${run_specific[0]},${run_specific[1]},$third_value"
            p=$((p + 1))
            prev_operation="$operation"
        else
            values_2="$values_2,$third_value"
        fi
    done <<< "$filtered_output"

    # Print the values to the output file
    echo "$values_1" >> "$OUTPUT_FILE"
    echo "$values_2" >> "$OUTPUT_FILE"

    # Print completion message
    echo "Arrangement completed. Output saved to $OUTPUT_FILE"

}

# Delete the ycsb database on MongoDB if any
log "=== Deleting the ycsb database on MongoDB, if any ==="
$MONGOSHELL "mongodb://localhost:27017/$DB_NAME?w=1" --eval "db.dropDatabase()" | tee -a $LOG_FILE

# Execute the load phase
log "=== Executing the load phase ==="
phase="load"
$YCSB load mongodb -s -P $WORKLOAD_FILE -p "mongodb.url=mongodb://localhost:27017/$DB_NAME" > $OUTPUT_CSV
cpu=$(ps aux | grep '[m]ongod' | awk '{sum+=$3} END {print sum}')
memory=$(ps aux | grep '[m]ongod' | awk '{sum+=$6} END {print sum/1024}')
write_result "TRUE"

# Experiment parameters
for epoch in $(seq 1 10); do
    for run in $(seq 1 10); do

        # Set proportions for insert mode
        perl -i -p -e "s/^insertproportion=.*/insertproportion=1/" $WORKLOAD_FILE
        perl -i -p -e "s/^readproportion=.*/readproportion=0/" $WORKLOAD_FILE

        # Extract the recordcount and operationcount from the workload file
        operationcount=$(grep -E '^operationcount=' "$WORKLOAD_FILE" | cut -d'=' -f2)
        recordcount=$(grep -E '^recordcount=' "$WORKLOAD_FILE" | cut -d'=' -f2)
        
        # Compute the new record number to be added
        updatedoperationcount=$(echo "($extendoperationcount / 10)" | bc)

        # Change operation count for insert mode
        perl -i -p -e "s/^operationcount=.*/operationcount=$updatedoperationcount/" $WORKLOAD_FILE

        $YCSB run mongodb -s -P $WORKLOAD_FILE -p "mongodb.url=mongodb://localhost:27017/$DB_NAME" > $OUTPUT_CSV

        # Set proportions for read mode
        perl -i -p -e "s/^insertproportion=.*/insertproportion=0/" $WORKLOAD_FILE
        perl -i -p -e "s/^readproportion=.*/readproportion=1/" $WORKLOAD_FILE

        # Compute new record count
        updatedrecordcount=$(echo "$recordcount + ($extendoperationcount / 10)" | bc)

        # Setting parameter values for read phase
        log "=== Setting parameter values for run phase ==="
        perl -i -p -e "s/^recordcount=.*/recordcount=$updatedrecordcount/" $WORKLOAD_FILE
        # Change operation count for read mode
        perl -i -p -e "s/^operationcount=.*/operationcount=$operationcount/" $WORKLOAD_FILE
        source "$WORKLOAD_FILE" 

        # Execute the run phase
        log "=== Executing the run phase with extendproportion=0 and read/update proportions=0.5 ==="
        phase="spread-run"
        $YCSB run mongodb -s -P $WORKLOAD_FILE -p "mongodb.url=mongodb://localhost:27017/$DB_NAME" > $OUTPUT_CSV
        cpu=$(ps aux | grep '[m]ongod' | awk '{sum+=$3} END {print sum}')
        memory=$(ps aux | grep '[m]ongod' | awk '{sum+=$6} END {print sum/1024}')
        write_result "FALSE"

    done

done

# Delete intermidiate temp files
rm -rf $LOG_FILE
rm -rf $OUTPUT_CSV

log "=== All steps completed. Results are logged in $LOG_FILE ==="
