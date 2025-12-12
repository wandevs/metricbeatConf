#!/bin/bash

# --- 1. Configuration and Interactive Input ---
SERVICE_NAME="system_resource_metric"
TIMER_NAME="${SERVICE_NAME}.timer" # 定义 Timer 文件名
# IMPORTANT: Replace this URL with the Raw link of your COMMAND-LINE-ARGUMENT script on GitHub
GITHUB_RAW_URL="https://raw.githubusercontent.com/wandevs/metricbeatConf/main/system_resource_metric.sh" 

REPO_DIR="/opt/${SERVICE_NAME}"
SCRIPT_NAME="${SERVICE_NAME}.sh"
SCRIPT_PATH="${REPO_DIR}/${SCRIPT_NAME}"
SERVICE_FILE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
TIMER_FILE_PATH="/etc/systemd/system/${TIMER_NAME}" # Timer 文件路径
USER_NAME=$(whoami) 
GROUP_NAME=$(id -gn)

echo "--- Automated Deployment for System Metrics Reporter (Timer Mode) ---"
# Interactive Input for Syslog Server Details
read -p "Enter SYSLOG Server IP/Hostname: " SYSLOG_SERVER
read -p "Enter SYSLOG Port: " SYSLOG_PORT

# Basic check to ensure input is not empty
if [ -z "$SYSLOG_SERVER" ] || [ -z "$SYSLOG_PORT" ]; then
    echo "ERROR: Server IP/Hostname or Port cannot be empty. Aborting deployment."
    exit 1
fi

echo "Configuration accepted: Server=${SYSLOG_SERVER}, Port=${SYSLOG_PORT}"
echo "-----------------------------------------------------"

# --- 2. Pre-check and Directory Setup ---
echo "--- Checking for 'curl' and setting up directory ---"
if ! command -v curl &> /dev/null; then
    echo "ERROR: 'curl' is required for authenticated download but is not installed."
    echo "Please install 'curl' manually (e.g., 'sudo apt install curl')."
    exit 1
fi
# Ensure the target directory exists
sudo mkdir -p ${REPO_DIR}

# --- 3. Download Shell Script ---
echo "--- 3. Downloading script file from GitHub Raw link: ${GITHUB_RAW_URL} ---"
if ! sudo curl -sS -o ${SCRIPT_PATH} ${GITHUB_RAW_URL}; then
    echo "ERROR: Failed to download file from ${GITHUB_RAW_URL}. Aborting deployment."
    exit 1
fi
echo "Script successfully downloaded to: ${SCRIPT_PATH}"

# --- 4. Set Permissions and Ownership ---
echo "--- 4. Setting script permissions and ownership ---"
sudo chmod +x ${SCRIPT_PATH}
sudo chown -R ${USER_NAME}:${GROUP_NAME} ${REPO_DIR}

# --- 5. Create systemd SERVICE File (CRITICAL FIX: Type=oneshot) ---
echo "--- 5. Creating systemd SERVICE file: ${SERVICE_FILE_PATH} ---"
sudo tee ${SERVICE_FILE_PATH} > /dev/null << EOF
[Unit]
Description=System Metrics Reporter Service (Task Definition)
After=network.target

[Service]
# CRITICAL FIX: Use 'oneshot' for scripts that run once and exit.
Type=oneshot 
# CRITICAL FIX: Restarting is handled by the Timer, so set this to 'no'.
Restart=no 
User=${USER_NAME}
WorkingDirectory=${REPO_DIR}
# Pass the user-inputted IP and Port as command-line arguments
ExecStart=${SCRIPT_PATH} ${SYSLOG_SERVER} ${SYSLOG_PORT}
StandardOutput=syslog
StandardError=syslog

[Install]
WantedBy=multi-user.target
EOF

# --- 6. Create systemd TIMER File (NEW STEP: Set Frequency) ---
echo "--- 6. Creating systemd TIMER file: ${TIMER_FILE_PATH} ---"
sudo tee ${TIMER_FILE_PATH} > /dev/null << EOF
[Unit]
Description=Runs the System Metrics Reporter every minute

[Timer]
# Schedule: Run the associated service every 60 seconds
OnUnitActiveSec=60s
# Set a random delay (up to 5 seconds) to spread load across multiple machines
RandomizedDelaySec=5s 

[Install]
WantedBy=timers.target
EOF

# --- 7. Apply Changes, Start Timer, and Check Status ---
echo "--- 7. Reloading systemd, enabling, and starting the TIMER ---"

# 重新加载 systemd 配置
sudo systemctl daemon-reload

# 停止并禁用旧的服务实例（如果存在）
# 确保在启动 Timer 之前，旧的 Service 实例被彻底禁用
sudo systemctl stop ${SERVICE_NAME}.service 2>/dev/null
sudo systemctl disable ${SERVICE_NAME}.service 2>/dev/null

# 启用并启动定时器 (Timer)
sudo systemctl enable ${SERVICE_NAME}.service
sudo systemctl start ${SERVICE_NAME}.service
sudo systemctl enable ${TIMER_NAME}
sudo systemctl start ${TIMER_NAME}

# --- 8. Check Status ---
echo "--- 8. Deployment complete. Checking TIMER status: ---"
sudo systemctl status ${TIMER_NAME} | grep -E "Active:|Loaded:"
echo ""
echo "Next run time (Local Time):"
sudo systemctl list-timers --all | grep ${TIMER_NAME}
