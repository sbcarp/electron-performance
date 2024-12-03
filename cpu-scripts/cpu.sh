#!/bin/bash

# List of process name patterns to monitor (partial matches)
process_names=("electron")

# Maximum number of processes to monitor per pattern
max_processes_per_pattern=10

# Directory of the script
script_dir="$(cd "$(dirname "$0")" && pwd)"

# Output CSV file in the script's directory
output_file="$script_dir/cpu_usage.csv"

# Build the header dynamically
header="Timestamp"
for pname in "${process_names[@]}"; do
    for ((i=1; i<=max_processes_per_pattern; i++)); do
        header="$header,${pname}_Process_Name_$i,${pname}_PID_$i,${pname}_CPU_Usage_$i"
    done
done
echo "$header" > "$output_file"

# Infinite loop to monitor processes every second
while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')  # Current timestamp
    line="$timestamp"  # Initialize the line with the timestamp
    for pname in "${process_names[@]}"; do
        # Get PIDs of processes matching the pattern
        pids=($(pgrep -f "$pname"))
        if [ ${#pids[@]} -eq 0 ]; then
            # No process found; add empty fields
            for ((i=1; i<=max_processes_per_pattern; i++)); do
                line="$line,,,"
            done
        else
            # Loop over each PID up to the maximum number
            for ((i=0; i<max_processes_per_pattern; i++)); do
                if [ $i -lt ${#pids[@]} ]; then
                    pid=${pids[$i]}
                    # Get process CPU usage and command
                    proc_info=$(ps -p "$pid" -o pid=,pcpu=,comm=)
                    if [ -n "$proc_info" ]; then
                        # Extract PID, CPU, and Command
                        pid=$(echo "$proc_info" | awk '{print $1}')
                        cpu=$(echo "$proc_info" | awk '{print $2}')
                        command=$(echo "$proc_info" | awk '{for(j=3;j<=NF;++j)printf $j" ";}')
                        # Remove commas to prevent CSV issues
                        command=$(echo "$command" | tr -d ',')
                        # Trim trailing space
                        command=$(echo "$command" | sed 's/ $//')
                        # Add to line
                        line="$line,\"$command\",$pid,$cpu"
                    else
                        # If process info is not available, add empty fields
                        line="$line,,,"
                    fi
                else
                    # No more processes; add empty fields
                    line="$line,,,"
                fi
            done
        fi
    done
    # Write the line to CSV file
    echo "$line" >> "$output_file"
    # Also output to screen
    echo "$line"
    sleep 1
done
