#!/bin/bash

# --- Configuration Parameters (Command-Line Arguments) ---

# Check if both required arguments (Server IP/Hostname = $1 and Port = $2) are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    # IMPORTANT: Output error to stderr so systemd can capture it properly
    echo "ERROR: Missing required arguments." >&2
    echo "Usage: $0 <SYSLOG_SERVER_IP> <SYSLOG_PORT>" >&2
    exit 1
fi

SYSLOG_SERVER="$1" # First argument from command line
SYSLOG_PORT="$2"   # Second argument from command line
LOG_NAME="system_metrics_node"
# --- Configuration Parameters End ---

# Collection function
collect_metrics() {
    
    # 1. CPU Cores (Using nproc - standard and simple)
    CPU_CORES=$(nproc)

    # 2. CPU Total Usage (Robust calculation from top's idle value)
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{
        # Logic to find the idle value robustly across different top outputs
        for (i=1; i<=NF; i++) {
            if ($i ~ /id/ || $i ~ /idle/) {
                idle_val = $(i-1);
                # Remove any possible % or , before calculation
                gsub(/[%,]/, "", idle_val);
                # Calculate 100 - idle and format to one decimal place
                printf "%.1f", 100 - idle_val;
                exit;
            }
        }
    }')
    
    # 3. Memory Info (In MB)
    MEM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
    MEM_USED=$(free -m | grep Mem | awk '{print $3}')
    MEM_FREE=$(free -m | grep Mem | awk '{print $4}')

    # 4. Disk Usage 
    DISK_TOTAL=$(df -h / | tail -1 | awk '{print $2}')
    DISK_USED=$(df -h / | tail -1 | awk '{print $3}')
    DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')

    # 5. System Load (1-minute average load)
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')

    # Format the message
    MESSAGE="hostname=$(hostname) cpu_usage=${CPU_USAGE}% cpu_cores=${CPU_CORES} mem_total=${MEM_TOTAL}MB mem_used=${MEM_USED}MB mem_free=${MEM_FREE}MB disk_total=${DISK_TOTAL} disk_used=${DISK_USED} disk_usage=${DISK_USAGE}% load_avg=${LOAD_AVG}"

    # Send to syslog server (using logger -n and -P)
    logger -n "$SYSLOG_SERVER" -P "$SYSLOG_PORT" -t "$LOG_NAME" -p "user.info" "$MESSAGE"

    # Check the exit status of the logger command
    if [ $? -eq 0 ]; then
        echo "[$(date '+%H:%M:%S')] Metrics sent successfully to $SYSLOG_SERVER:$SYSLOG_PORT."
    else
        echo "[$(date '+%H:%M:%S')] ERROR: Failed to send metrics to $SYSLOG_SERVER:$SYSLOG_PORT." >&2
    fi
}

# Execute collection and send
collect_metrics