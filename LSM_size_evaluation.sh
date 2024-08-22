#!/bin/bash

YCSB="bin/ycsb.sh"

# Path to the RocksDB data directory
DB_PATH="/tmp/rocksdb_data6"
BACKUP_DIR="/tmp/rocksdb_backup"
RESTORE_DIR="/tmp/rocksdb_restore"
BACKUP_PROGRAM="./rocksdb_dumpandload/rocksdb_dump"
RESTORE_PROGRAM="./rocksdb_dumpandload/rocksdb_load"

# Define the workload file and the log file
WORKLOAD_FILE="./workloads/workloada-extend"
LOG_FILE="./ycsb_results.log"
OUTPUT_CSV="./analysis/output.csv"
SIZE_CSV="./sizes_INSERT_temp.csv"

# Define input and output filenames
INPUT_FILE="./analysis/output.csv"
OUTPUT_FILE="./temp.csv"

# Extend phase experiment parameters
extendproportion_extend="0"
readproportion_extend="0"
updateproportion_extend="0"
scanproportion_extend="0"
insertproportion_extend="1"

# Function to get RAM usage on macOS
get_ram_usage() {
  # Get the memory statistics from vm_stat
  vm_stat_output=$(vm_stat)
  # Extract the page size (in bytes)
  page_size=$(sysctl -n hw.pagesize)
  # Extract the number of free and active pages
  free_pages=$(echo "$vm_stat_output" | grep "Pages free:" | awk '{print $3}' | sed 's/\.//')
  speculative_pages=$(echo "$vm_stat_output" | grep "Pages speculative:" | awk '{print $3}' | sed 's/\.//')
  inactive_pages=$(echo "$vm_stat_output" | grep "Pages inactive:" | awk '{print $3}' | sed 's/\.//')
  wired_pages=$(echo "$vm_stat_output" | grep "Pages wired down:" | awk '{print $4}' | sed 's/\.//')
  active_pages=$(echo "$vm_stat_output" | grep "Pages active:" | awk '{print $3}' | sed 's/\.//')
  # Calculate the total free memory
  total_free_memory=$(( (free_pages + speculative_pages + inactive_pages) * page_size ))
  # Calculate the total used memory (active + wired)
  total_used_memory=$((((active_pages + wired_pages) * page_size )/1024))

  echo "$total_used_memory"
}

# Function to check SST and log sizes
check_sizes() {
  while kill -0 $YCSB_PID 2> /dev/null; do
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    sstsize=$(du -sck "$DB_PATH"/*.sst | tail -n 1 | cut -f1)
    logsize=$(du -sck "$DB_PATH"/*.log | tail -n 1 | cut -f1)
    ram_usage=$(get_ram_usage)
    echo "$timestamp, $sstsize, $logsize, $ram_usage" >> "$SIZE_CSV"
  done
}

# Step 3: Setting parameter values for extend phase
perl -i -p -e "s/^extendproportion=.*/extendproportion=$extendproportion_extend/" $WORKLOAD_FILE
perl -i -p -e "s/^readproportion=.*/readproportion=$readproportion_extend/" $WORKLOAD_FILE
perl -i -p -e "s/^updateproportion=.*/updateproportion=$updateproportion_extend/" $WORKLOAD_FILE
perl -i -p -e "s/^scanproportion=.*/scanproportion=$scanproportion_extend/" $WORKLOAD_FILE
perl -i -p -e "s/^insertproportion=.*/insertproportion=$insertproportion_extend/" $WORKLOAD_FILE
source "$WORKLOAD_FILE"

#Load data
$YCSB load rocksdb -s -P "$WORKLOAD_FILE" -p rocksdb.dir="$DB_PATH"

# Initialize the size log CSV with headers
echo "Timestamp, SST Size (KB), Log Size (KB), RAM Usage (KB)"  > "$SIZE_CSV"

# Run the YCSB command in the background
$YCSB run rocksdb -s -P "$WORKLOAD_FILE" -p rocksdb.dir="$DB_PATH" > "$OUTPUT_CSV" &
YCSB_PID=$!

# Check SST and log sizes in the background
check_sizes &

# Wait for the YCSB command to finish
wait $YCSB_PID