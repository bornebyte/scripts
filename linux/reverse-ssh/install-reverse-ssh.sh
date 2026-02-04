#!/bin/bash

#############################################################################
# Reverse SSH Tunnel Installation Script
#
# This script installs and configures the reverse SSH tunnel service
# to run automatically on system boot with root privileges.
#
# Usage: sudo ./install-reverse-ssh.sh
#############################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
print_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

print_info "=========================================="
print_info "Reverse SSH Tunnel Installation"
print_info "=========================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define installation paths
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/reverse-ssh"
SERVICE_FILE="/etc/systemd/system/reverse-ssh-tunnel.service"
SCRIPT_NAME="reverse-ssh-tunnel.sh"

# Check if required files exist
if [[ ! -f "$SCRIPT_DIR/$SCRIPT_NAME" ]]; then
    print_error "Script file not found: $SCRIPT_DIR/$SCRIPT_NAME"
    exit 1
fi

if [[ ! -f "$SCRIPT_DIR/reverse-ssh-tunnel.service" ]]; then
    print_error "Service file not found: $SCRIPT_DIR/reverse-ssh-tunnel.service"
    exit 1
fi

if [[ ! -f "$SCRIPT_DIR/reverse-ssh-config.conf" ]]; then
    print_error "Configuration file not found: $SCRIPT_DIR/reverse-ssh-config.conf"
    exit 1
fi

# Create configuration directory
print_info "Creating configuration directory: $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

# Copy configuration file
if [[ -f "$CONFIG_DIR/config.conf" ]]; then
    print_warning "Configuration file already exists. Creating backup..."
    cp "$CONFIG_DIR/config.conf" "$CONFIG_DIR/config.conf.backup.$(date +%Y%m%d_%H%M%S)"
fi

print_info "Installing configuration file..."
cp "$SCRIPT_DIR/reverse-ssh-config.conf" "$CONFIG_DIR/config.conf"
chmod 600 "$CONFIG_DIR/config.conf"

# Copy main script
print_info "Installing main script to $INSTALL_DIR..."
cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"
chmod 755 "$INSTALL_DIR/$SCRIPT_NAME"

# Copy systemd service file
print_info "Installing systemd service..."
cp "$SCRIPT_DIR/reverse-ssh-tunnel.service" "$SERVICE_FILE"
chmod 644 "$SERVICE_FILE"

# Reload systemd
print_info "Reloading systemd daemon..."
systemctl daemon-reload

print_success "Installation completed successfully!"
echo ""

# Prompt for SSH key setup
print_info "=========================================="
print_info "SSH Key Setup"
print_info "=========================================="

read -p "Do you want to generate an SSH key for the tunnel now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SSH_KEY_PATH="/root/.ssh/reverse_tunnel_key"
    SSH_KEY_DIR=$(dirname "$SSH_KEY_PATH")
    
    mkdir -p "$SSH_KEY_DIR"
    chmod 700 "$SSH_KEY_DIR"
    
    if [[ -f "$SSH_KEY_PATH" ]]; then
        print_warning "SSH key already exists at $SSH_KEY_PATH"
        read -p "Overwrite existing key? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing key"
        else
            print_info "Generating new SSH key..."
            ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "reverse-tunnel-$(hostname)"
            print_success "SSH key generated: $SSH_KEY_PATH"
        fi
    else
        print_info "Generating SSH key..."
        ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "reverse-tunnel-$(hostname)"
        print_success "SSH key generated: $SSH_KEY_PATH"
    fi
    
    chmod 600 "$SSH_KEY_PATH"
    
    print_info "Public key:"
    cat "${SSH_KEY_PATH}.pub"
    echo ""
    print_warning "Copy this public key to your remote server's ~/.ssh/authorized_keys file"
fi

echo ""
print_info "=========================================="
print_info "Configuration"
print_info "=========================================="
print_warning "IMPORTANT: Edit the configuration file before starting the service:"
print_info "  sudo nano $CONFIG_DIR/config.conf"
echo ""
print_info "Required settings:"
print_info "  - REMOTE_HOST: Your remote server hostname or IP"
print_info "  - REMOTE_USER: Username on remote server"
print_info "  - REVERSE_PORT: Port on remote server for reverse tunnel"
print_info "  - SSH_KEY_PATH: Path to SSH private key"
echo ""

# Ask if user wants to edit config now
read -p "Do you want to edit the configuration file now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ${EDITOR:-nano} "$CONFIG_DIR/config.conf"
fi

echo ""
print_info "=========================================="
print_info "Service Management"
print_info "=========================================="
print_info "Enable service (start on boot):  sudo systemctl enable reverse-ssh-tunnel"
print_info "Start service now:               sudo systemctl start reverse-ssh-tunnel"
print_info "Check service status:            sudo systemctl status reverse-ssh-tunnel"
print_info "View logs:                       sudo journalctl -u reverse-ssh-tunnel -f"
print_info "Stop service:                    sudo systemctl stop reverse-ssh-tunnel"
print_info "Disable service:                 sudo systemctl disable reverse-ssh-tunnel"
echo ""

# Ask if user wants to enable and start the service
read -p "Do you want to enable and start the service now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Enabling service..."
    systemctl enable reverse-ssh-tunnel
    
    print_info "Starting service..."
    systemctl start reverse-ssh-tunnel
    
    sleep 2
    
    print_info "Service status:"
    systemctl status reverse-ssh-tunnel --no-pager || true
    
    print_success "Service is running!"
    print_info "View logs with: sudo journalctl -u reverse-ssh-tunnel -f"
else
    print_info "Service not started. Enable and start manually when ready."
fi

echo ""
print_success "=========================================="
print_success "Installation Complete!"
print_success "=========================================="
