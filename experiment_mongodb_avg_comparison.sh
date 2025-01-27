#!/bin/bash

#sudo mongod --config /etc/mongod.conf &         # Start first instance on 27017
#sudo mongod --config /etc/mongod_28018.conf &   # Start second instance on 28018

YCSB="bin/ycsb.sh"
MONGOSHELL="/usr/bin/mongosh"
MONGODUMP="mongodump"
MONGORESTORE="mongorestore"

# Define the workload file and the log file
WORKLOAD_FILE="./workloads/workloada-extend"
LOG_FILE="./ycsb_results.log"
OUTPUT_CSV="./analysis/output.csv"

# Define input and output filenames
INPUT_FILE="./analysis/output.csv"
OUTPUT_FILE="./analysis/Data/mongodb_exp_run1_new_uniform.csv"

# DB names
DB_NAME="ycsb"
BACKUP_DB_NAME="ycsb_backup"
UNCHANGE_DB_NAME="ycsb_unchange"

# Key size gathering
KEY_SIZE_LOG="key_sizes.csv"
KEY_SIZE_FILE="./analysis/Data/key_size_dist_mongodb_run1_new_uniform.csv"

# Extend phase experiment parameters
extendproportion_extend="1"
readproportion_extend="0"
updateproportion_extend="0"
scanproportion_extend="0"
insertproportion_extend="0"
requestdistribution_extend="zipfian"

# After extend phase experiment parameters
extendproportion_postextend="0"
readproportion_postextend="1"
updateproportion_postextend="0"
scanproportion_postextend="0"
insertproportion_postextend="0"
extendvaluesize_postextend="0"
requestdistribution_postextend="uniform"

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

# Function to append values for the first iteration
append_first_iteration() {
    echo "Appending first iteration..."
    awk -F, 'NR==1 {next} {print $1 "," $2}' "$KEY_SIZE_LOG" >> "$KEY_SIZE_FILE"
    echo "First iteration: Appended values from $KEY_SIZE_LOG to $KEY_SIZE_FILE"
}

# Function to append sizes for subsequent iterations
append_subsequent_iterations() {
    echo "Appending subsequent iteration $iteration..."
    awk -F, '
        NR==FNR {if (NR > 1) {key_sizes[$1]=$2;} next}  # Read key_sizes from log
        FNR==1 {print $0 ",Run'$iteration'"; next}     # Add new run column in the header
        ($1 in key_sizes) {print $0 "," key_sizes[$1]}  # Append size for existing key
        !($1 in key_sizes) {print $0 ",0"}              # If key is not found, append 0
    ' "$KEY_SIZE_LOG" "$KEY_SIZE_FILE" > temp.csv

    mv temp.csv "$KEY_SIZE_FILE"  # Overwrite the file with updated content
    echo "Iteration $iteration: Appended new size values from $KEY_SIZE_LOG to $KEY_SIZE_FILE"
}

# Delete the ycsb database on MongoDB if any
log "=== Deleting the ycsb database on MongoDB, if any ==="
$MONGOSHELL "mongodb://localhost:27017/$DB_NAME?w=1" --eval "db.dropDatabase()" | tee -a $LOG_FILE
$MONGOSHELL "mongodb://localhost:27017/$UNCHANGE_DB_NAME?w=1" --eval "db.dropDatabase()" | tee -a $LOG_FILE

# Execute the load phase
log "=== Executing the load phase ==="
phase="load"
$YCSB load mongodb -s -P $WORKLOAD_FILE -p "mongodb.url=mongodb://localhost:27017/$DB_NAME" > $OUTPUT_CSV
cpu=$(ps aux | grep '[m]ongod' | awk '{sum+=$3} END {print sum}')
memory=$(ps aux | grep '[m]ongod' | awk '{sum+=$6} END {print sum/1024}')
write_result "TRUE"

# Load unchange value size (reference) DB
$YCSB load mongodb -s -P $WORKLOAD_FILE -p "mongodb.url=mongodb://localhost:27017/$UNCHANGE_DB_NAME" > $OUTPUT_CSV


# Experiment parameters
for epoch in $(seq 1 10); do
    for run in $(seq 1 10); do

        # Record operation count from workload configuration file
        opscount=$(grep -E '^operationcount=' "$WORKLOAD_FILE" | cut -d'=' -f2)

        # Setting parameter values for extend phase
        log "=== Setting parameter values for extend phase ==="
        perl -i -p -e "s/^extendproportion=.*/extendproportion=$extendproportion_extend/" $WORKLOAD_FILE
        perl -i -p -e "s/^readproportion=.*/readproportion=$readproportion_extend/" $WORKLOAD_FILE
        perl -i -p -e "s/^updateproportion=.*/updateproportion=$updateproportion_extend/" $WORKLOAD_FILE
        perl -i -p -e "s/^scanproportion=.*/scanproportion=$scanproportion_extend/" $WORKLOAD_FILE
        perl -i -p -e "s/^insertproportion=.*/insertproportion=$insertproportion_extend/" $WORKLOAD_FILE
        perl -i -p -e "s/^requestdistribution=.*/requestdistribution=$requestdistribution_extend/" $WORKLOAD_FILE
        perl -i -p -e "s/^operationcount=.*/operationcount=$extendoperationcount/" $WORKLOAD_FILE
        source "$WORKLOAD_FILE"

        # Execute the run phase
        log "=== Executing the run phase with extendproportion=0.2 and other proportions=0 ==="
        phase="extend"
        $YCSB run mongodb -s -P $WORKLOAD_FILE -p "mongodb.url=mongodb://localhost:27017/$DB_NAME" > $OUTPUT_CSV
        cpu=$(ps aux | grep '[m]ongod' | awk '{sum+=$3} END {print sum}')
        memory=$(ps aux | grep '[m]ongod' | awk '{sum+=$6} END {print sum/1024}')
        write_result "FALSE"

        # Setting parameter values for run phase
        log "=== Setting parameter values for run phase ==="
        perl -i -p -e "s/^extendproportion=.*/extendproportion=$extendproportion_postextend/" $WORKLOAD_FILE
        perl -i -p -e "s/^readproportion=.*/readproportion=$readproportion_postextend/" $WORKLOAD_FILE
        perl -i -p -e "s/^updateproportion=.*/updateproportion=$updateproportion_postextend/" $WORKLOAD_FILE
        perl -i -p -e "s/^scanproportion=.*/scanproportion=$scanproportion_postextend/" $WORKLOAD_FILE
        perl -i -p -e "s/^insertproportion=.*/insertproportion=$insertproportion_postextend/" $WORKLOAD_FILE
        perl -i -p -e "s/^requestdistribution=.*/requestdistribution=$requestdistribution_postextend/" $WORKLOAD_FILE
        perl -i -p -e "s/^operationcount=.*/operationcount=$opscount/" $WORKLOAD_FILE
        source "$WORKLOAD_FILE"

        # Execute the run phase
        log "=== Executing the run phase with extendproportion=0 and read/update proportions=0.5 ==="
        phase="run"
        $YCSB run mongodb -s -P $WORKLOAD_FILE -p "mongodb.url=mongodb://localhost:27017/$DB_NAME" > $OUTPUT_CSV
        cpu=$(ps aux | grep '[m]ongod' | awk '{sum+=$3} END {print sum}')
        memory=$(ps aux | grep '[m]ongod' | awk '{sum+=$6} END {print sum/1024}')
        write_result "FALSE"

        # Workload with unchanging value sizes
        log "=== Executing the run phase with extendproportion=0 and read/update proportions=0.5 ==="
        phase="reference"
        $YCSB run mongodb -s -P $WORKLOAD_FILE -p "mongodb.url=mongodb://localhost:27017/$UNCHANGE_DB_NAME" > $OUTPUT_CSV
        cpu=$(ps aux | grep '[m]ongod' | awk '{sum+=$3} END {print sum}')
        memory=$(ps aux | grep '[m]ongod' | awk '{sum+=$6} END {print sum/1024}')
        write_result "FALSE"

        if (( $((10*($epoch-1)+$run)) % 1 == 0 )); then
            phase="clean-run"

            echo "Backing up the database started"
            $MONGODUMP --uri="mongodb://localhost:27017/$DB_NAME" --archive | $MONGORESTORE --uri="mongodb://localhost:28018/$DB_NAME" --archive --drop
            echo "Backing up the database finished" 

            $YCSB run mongodb -s -P $WORKLOAD_FILE -p "mongodb.url=mongodb://localhost:28018/$DB_NAME" > $OUTPUT_CSV
            cpu=$(ps aux | grep '[m]ongod' | awk '{sum+=$3} END {print sum}')
            memory=$(ps aux | grep '[m]ongod' | awk '{sum+=$6} END {print sum/1024}')
            write_result "FALSE"

            # Extract the recordcount from the workload file
            recordcount=$(grep -E '^recordcount=' "$WORKLOAD_FILE" | cut -d'=' -f2)

            # Calculate total size of all records in MongoDB
            total_size=$(mongosh "mongodb://localhost:28018/$DB_NAME" --quiet --eval "
                JSON.stringify(db.getSiblingDB('$DB_NAME').usertable.aggregate([
                { \$project: { docSize: { \$bsonSize: '\$\$ROOT' } } },
                { \$group: { _id: null, totalSize: { \$sum: '\$docSize' } } }
                ]).toArray())
                " | jq -r '.[0].totalSize')

            # Calculate average field length
            fieldlengthaverage=$(echo "$total_size / (10 * $recordcount)" | bc)

            echo "$total_size" "$fieldlengthaverage"

            # Changing the value size for comparison
            perl -i -p -e "s/^fieldlength=.*/fieldlength=$fieldlengthaverage/" $WORKLOAD_FILE
            source "$WORKLOAD_FILE"

            $MONGOSHELL "mongodb://localhost:28018/$DB_NAME" --eval "db.dropDatabase()" | tee -a $LOG_FILE

            # Resetting the database with new data load
            log "=== Executing the load phase for the comparison study ==="
            $YCSB load mongodb -s -P $WORKLOAD_FILE -p "mongodb.url=mongodb://localhost:28018/$DB_NAME" > $OUTPUT_CSV

            # Changing the value size for comparison
            perl -i -p -e "s/^fieldlength=.*/fieldlength=$fieldlengthoriginal/" $WORKLOAD_FILE
            source "$WORKLOAD_FILE"

            # Execute the run phase
            phase="avg-run"
            $YCSB run mongodb -s -P $WORKLOAD_FILE -p "mongodb.url=mongodb://localhost:28018/$DB_NAME" > $OUTPUT_CSV
            cpu=$(ps aux | grep '[m]ongod' | awk '{sum+=$3} END {print sum}')
            memory=$(ps aux | grep '[m]ongod' | awk '{sum+=$6} END {print sum/1024}')
            write_result "FALSE"

            $MONGOSHELL "mongodb://localhost:28018/$DB_NAME" --eval "db.dropDatabase()" | tee -a $LOG_FILE

        fi
    done

done

log "=== All steps completed. Results are logged in $LOG_FILE ==="
