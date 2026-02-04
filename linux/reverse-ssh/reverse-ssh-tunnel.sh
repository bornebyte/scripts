#!/bin/bash

#############################################################################
# Reverse SSH Tunnel Manager
# 
# This script establishes and maintains a reverse SSH tunnel to allow
# remote access to this machine. Designed to run as a systemd service
# with root privileges.
#
# Author: Auto-generated
# License: Use at your own risk
#############################################################################

set -euo pipefail

# Default configuration file path
CONFIG_FILE="${1:-/etc/reverse-ssh/config.conf}"

# Source configuration file
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# Initialize variables with defaults if not set
RECONNECT_INTERVAL="${RECONNECT_INTERVAL:-30}"
MAX_RETRY_ATTEMPTS="${MAX_RETRY_ATTEMPTS:-0}"
CONNECTION_TIMEOUT="${CONNECTION_TIMEOUT:-10}"
LOG_FILE="${LOG_FILE:-/var/log/reverse-ssh-tunnel.log}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"
ENABLE_COMPRESSION="${ENABLE_COMPRESSION:-yes}"
BIND_ADDRESS="${BIND_ADDRESS:-localhost}"
SSH_EXTRA_OPTS="${SSH_EXTRA_OPTS:-}"

# Ensure log directory exists
LOG_DIR=$(dirname "$LOG_FILE")
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Also output to stderr for systemd journal
    echo "[$level] $message" >&2
}

log_debug() { [[ "$LOG_LEVEL" == "DEBUG" ]] && log "DEBUG" "$@"; }
log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }

# Validate configuration
validate_config() {
    local errors=0
    
    if [[ -z "${REMOTE_HOST:-}" ]]; then
        log_error "REMOTE_HOST is not set in configuration"
        errors=$((errors + 1))
    fi
    
    if [[ -z "${REMOTE_USER:-}" ]]; then
        log_error "REMOTE_USER is not set in configuration"
        errors=$((errors + 1))
    fi
    
    if [[ -z "${SSH_KEY_PATH:-}" ]]; then
        log_error "SSH_KEY_PATH is not set in configuration"
        errors=$((errors + 1))
    elif [[ ! -f "$SSH_KEY_PATH" ]]; then
        log_error "SSH key not found: $SSH_KEY_PATH"
        errors=$((errors + 1))
    fi
    
    if [[ -z "${REVERSE_PORT:-}" ]]; then
        log_error "REVERSE_PORT is not set in configuration"
        errors=$((errors + 1))
    fi
    
    if [[ -z "${LOCAL_SSH_PORT:-}" ]]; then
        log_error "LOCAL_SSH_PORT is not set in configuration"
        errors=$((errors + 1))
    fi
    
    return $errors
}

# Check if tunnel is already running
is_tunnel_running() {
    pgrep -f "ssh.*${REMOTE_HOST}.*${REVERSE_PORT}:localhost:${LOCAL_SSH_PORT}" > /dev/null 2>&1
}

# Kill existing tunnel
kill_existing_tunnel() {
    if is_tunnel_running; then
        log_info "Killing existing tunnel process..."
        pkill -f "ssh.*${REMOTE_HOST}.*${REVERSE_PORT}:localhost:${LOCAL_SSH_PORT}" || true
        sleep 2
    fi
}

# Establish SSH tunnel
establish_tunnel() {
    local ssh_opts="-N -T"
    
    # Add compression if enabled
    if [[ "$ENABLE_COMPRESSION" == "yes" ]]; then
        ssh_opts="$ssh_opts -C"
    fi
    
    # Build SSH command
    local ssh_cmd="ssh $ssh_opts \
        -i '$SSH_KEY_PATH' \
        -p $REMOTE_PORT \
        -o ConnectTimeout=$CONNECTION_TIMEOUT \
        -o ExitOnForwardFailure=yes \
        $SSH_EXTRA_OPTS \
        -R ${BIND_ADDRESS}:${REVERSE_PORT}:localhost:${LOCAL_SSH_PORT} \
        ${REMOTE_USER}@${REMOTE_HOST}"
    
    log_info "Establishing reverse SSH tunnel to ${REMOTE_HOST}:${REVERSE_PORT}"
    log_debug "SSH command: $ssh_cmd"
    
    # Execute SSH tunnel
    eval "$ssh_cmd"
}

# Main connection loop
main_loop() {
    local retry_count=0
    
    while true; do
        # Check if we've exceeded max retry attempts
        if [[ $MAX_RETRY_ATTEMPTS -gt 0 ]] && [[ $retry_count -ge $MAX_RETRY_ATTEMPTS ]]; then
            log_error "Maximum retry attempts ($MAX_RETRY_ATTEMPTS) reached. Exiting."
            exit 1
        fi
        
        # Kill any existing tunnels
        kill_existing_tunnel
        
        # Attempt to establish tunnel
        log_info "Connection attempt #$((retry_count + 1))"
        
        if establish_tunnel; then
            log_warn "SSH tunnel disconnected normally"
        else
            local exit_code=$?
            log_error "SSH tunnel failed with exit code: $exit_code"
        fi
        
        # Increment retry counter
        retry_count=$((retry_count + 1))
        
        # Wait before reconnecting
        log_info "Waiting $RECONNECT_INTERVAL seconds before reconnecting..."
        sleep "$RECONNECT_INTERVAL"
    done
}

# Signal handlers
cleanup() {
    log_info "Received termination signal. Cleaning up..."
    kill_existing_tunnel
    exit 0
}

trap cleanup SIGTERM SIGINT SIGQUIT

# Main execution
main() {
    log_info "=========================================="
    log_info "Reverse SSH Tunnel Manager Starting"
    log_info "=========================================="
    log_info "Configuration file: $CONFIG_FILE"
    log_info "Remote server: ${REMOTE_HOST}:${REMOTE_PORT}"
    log_info "Reverse port: ${REVERSE_PORT}"
    log_info "Local SSH port: ${LOCAL_SSH_PORT}"
    log_info "SSH key: ${SSH_KEY_PATH}"
    
    # Validate configuration
    if ! validate_config; then
        log_error "Configuration validation failed. Exiting."
        exit 1
    fi
    
    log_info "Configuration validated successfully"
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_warn "Not running as root. Some operations may fail."
    fi
    
    # Start main connection loop
    main_loop
}

# Run main function
main
