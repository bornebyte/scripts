# Reverse SSH Tunnel - Remote Access System

A comprehensive Linux program that establishes and maintains a persistent reverse SSH tunnel, enabling full remote control of your Linux machine. The system starts automatically on boot with root privileges and reconnects automatically if the connection drops.

## 🎯 Features

- **Automatic Boot Startup**: Runs as a systemd service with root privileges
- **Configuration-Driven**: All settings managed through a single configuration file
- **Auto-Reconnect**: Automatically reconnects if connection is lost
- **Comprehensive Logging**: Detailed logs for monitoring and debugging
- **Secure SSH Key Authentication**: Uses SSH key pairs for secure authentication
- **Full Root Access**: Runs with root privileges for complete system control
- **Resource Efficient**: Minimal CPU and memory footprint
- **Customizable**: Multiple configuration options for different scenarios

## 📋 Components

1. **reverse-ssh-tunnel.sh** - Main script that establishes and maintains the tunnel
2. **reverse-ssh-config.conf** - Configuration file with all settings
3. **reverse-ssh-tunnel.service** - Systemd service file for automatic startup
4. **install-reverse-ssh.sh** - Installation script for easy setup

## 🚀 Quick Start

### Prerequisites

- Linux system with systemd
- Root access (sudo)
- SSH client installed
- Access to a remote server with SSH

### Installation

1. **Download all files to a directory:**
   ```bash
   cd /home/shubham/dev/scripts/linux/
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x reverse-ssh-tunnel.sh install-reverse-ssh.sh
   ```

3. **Run the installation script as root:**
   ```bash
   sudo ./install-reverse-ssh.sh
   ```

4. **Follow the interactive prompts:**
   - Generate SSH key (or use existing)
   - Edit configuration file
   - Enable and start the service

### Manual Installation

If you prefer manual installation:

1. **Copy files to system locations:**
   ```bash
   sudo mkdir -p /etc/reverse-ssh
   sudo cp reverse-ssh-config.conf /etc/reverse-ssh/config.conf
   sudo cp reverse-ssh-tunnel.sh /usr/local/bin/
   sudo cp reverse-ssh-tunnel.service /etc/systemd/system/
   ```

2. **Set permissions:**
   ```bash
   sudo chmod 755 /usr/local/bin/reverse-ssh-tunnel.sh
   sudo chmod 600 /etc/reverse-ssh/config.conf
   sudo chmod 644 /etc/systemd/system/reverse-ssh-tunnel.service
   ```

3. **Reload systemd:**
   ```bash
   sudo systemctl daemon-reload
   ```

## ⚙️ Configuration

Edit the configuration file at `/etc/reverse-ssh/config.conf`:

```bash
sudo nano /etc/reverse-ssh/config.conf
```

### Essential Settings

- **REMOTE_HOST**: Your remote server's hostname or IP address
- **REMOTE_USER**: Username on the remote server
- **REMOTE_PORT**: SSH port on remote server (usually 22)
- **REVERSE_PORT**: Port on remote server that will tunnel back (e.g., 2222)
- **SSH_KEY_PATH**: Path to SSH private key (default: /root/.ssh/reverse_tunnel_key)

### Example Configuration

```bash
REMOTE_HOST="myserver.example.com"
REMOTE_PORT="22"
REMOTE_USER="tunneluser"
REVERSE_PORT="2222"
LOCAL_SSH_PORT="22"
SSH_KEY_PATH="/root/.ssh/reverse_tunnel_key"
```

## 🔑 SSH Key Setup

### Generate SSH Key Pair

```bash
sudo ssh-keygen -t ed25519 -f /root/.ssh/reverse_tunnel_key -N "" -C "reverse-tunnel-$(hostname)"
```

### Copy Public Key to Remote Server

```bash
sudo cat /root/.ssh/reverse_tunnel_key.pub
```

Copy the output and add it to `~/.ssh/authorized_keys` on your remote server:

```bash
# On remote server
echo "ssh-ed25519 AAAAC3Nza... reverse-tunnel-hostname" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Configure Remote Server

On your remote server, ensure the following SSH configuration allows reverse tunnels:

```bash
# /etc/ssh/sshd_config
GatewayPorts yes  # or 'clientspecified' for more security
```

Restart SSH service on remote server:
```bash
sudo systemctl restart sshd
```

## 🎮 Service Management

### Enable Service (Start on Boot)
```bash
sudo systemctl enable reverse-ssh-tunnel
```

### Start Service
```bash
sudo systemctl start reverse-ssh-tunnel
```

### Check Status
```bash
sudo systemctl status reverse-ssh-tunnel
```

### View Live Logs
```bash
sudo journalctl -u reverse-ssh-tunnel -f
```

### Stop Service
```bash
sudo systemctl stop reverse-ssh-tunnel
```

### Disable Service
```bash
sudo systemctl disable reverse-ssh-tunnel
```

### Restart Service
```bash
sudo systemctl restart reverse-ssh-tunnel
```

## 🔌 Connecting from Remote Server

Once the tunnel is established, connect from your remote server:

```bash
# On remote server, connect to your local machine
ssh -p 2222 root@localhost
```

This connects you to your local machine with full root access!

### Port Forwarding

You can also access other services on your local machine:

```bash
# Example: Access web server on local machine
ssh -L 8080:localhost:80 -p 2222 root@localhost
```

## 📊 Monitoring and Logs

### View Service Logs
```bash
# Last 50 lines
sudo journalctl -u reverse-ssh-tunnel -n 50

# Follow logs in real-time
sudo journalctl -u reverse-ssh-tunnel -f

# Logs since boot
sudo journalctl -u reverse-ssh-tunnel -b
```

### Check Log File
```bash
sudo tail -f /var/log/reverse-ssh-tunnel.log
```

### Check Connection Status
```bash
# Check if tunnel process is running
ps aux | grep "ssh.*reverse"

# Check if port is listening on remote server (run on remote server)
ss -tlnp | grep 2222
```

## 🔧 Troubleshooting

### Service Won't Start

1. **Check configuration:**
   ```bash
   sudo cat /etc/reverse-ssh/config.conf
   ```

2. **Test SSH connection manually:**
   ```bash
   sudo ssh -i /root/.ssh/reverse_tunnel_key -p 22 user@remote-host
   ```

3. **Check logs:**
   ```bash
   sudo journalctl -u reverse-ssh-tunnel -n 100
   ```

### Connection Keeps Dropping

1. **Increase ServerAlive intervals in config:**
   ```bash
   SSH_EXTRA_OPTS="-o ServerAliveInterval=30 -o ServerAliveCountMax=5"
   ```

2. **Check network stability**

3. **Review logs for errors:**
   ```bash
   sudo tail -100 /var/log/reverse-ssh-tunnel.log
   ```

### Permission Denied

1. **Verify SSH key is correct:**
   ```bash
   sudo cat /root/.ssh/reverse_tunnel_key.pub
   ```

2. **Ensure public key is in remote server's authorized_keys**

3. **Check key permissions:**
   ```bash
   sudo chmod 600 /root/.ssh/reverse_tunnel_key
   ```

### Port Already in Use (on remote server)

1. **Kill existing tunnel:**
   ```bash
   # On remote server
   pkill -f "sshd.*2222"
   ```

2. **Change REVERSE_PORT in config to a different port**

## 🔒 Security Considerations

⚠️ **IMPORTANT SECURITY WARNINGS:**

1. **Full Root Access**: This system provides complete root access to your machine. Only use with trusted remote servers.

2. **SSH Key Protection**: Keep your SSH private key secure. Anyone with access to this key can control your machine.

3. **Remote Server Security**: Ensure your remote server is secure, as it becomes a gateway to your local machine.

4. **Network Exposure**: By default, the tunnel binds to localhost on the remote server. To restrict access further:
   ```bash
   BIND_ADDRESS="localhost"  # Only accessible from remote server itself
   ```

5. **Firewall**: Configure firewall rules on both local and remote machines appropriately.

6. **Monitoring**: Regularly check logs for unauthorized access attempts.

### Recommendations

- Use strong SSH keys (ed25519 or RSA 4096-bit)
- Implement fail2ban on the remote server
- Use a dedicated user with sudo access instead of direct root (modify service)
- Regularly update both systems
- Monitor logs for suspicious activity
- Consider using a VPN in addition to SSH tunnel

## 📝 Advanced Configuration

### Multiple Tunnels

To create multiple reverse tunnels, create separate configuration files:

```bash
sudo cp /etc/reverse-ssh/config.conf /etc/reverse-ssh/config-server2.conf
```

Create a second service instance:
```bash
sudo cp /etc/systemd/system/reverse-ssh-tunnel.service /etc/systemd/system/reverse-ssh-tunnel-server2.service
```

Edit the new service file to use the second config file.

### Custom Reconnect Logic

Modify `RECONNECT_INTERVAL` and `MAX_RETRY_ATTEMPTS` in config:

```bash
RECONNECT_INTERVAL="60"      # Wait 60 seconds between attempts
MAX_RETRY_ATTEMPTS="10"      # Try max 10 times (0 = infinite)
```

### Additional Port Forwards

Add more port forwards by modifying the SSH command in the script:

```bash
-R 2222:localhost:22 -R 8080:localhost:80 -R 3306:localhost:3306
```

## 🗑️ Uninstallation

To completely remove the reverse SSH tunnel system:

```bash
# Stop and disable service
sudo systemctl stop reverse-ssh-tunnel
sudo systemctl disable reverse-ssh-tunnel

# Remove files
sudo rm /etc/systemd/system/reverse-ssh-tunnel.service
sudo rm /usr/local/bin/reverse-ssh-tunnel.sh
sudo rm -rf /etc/reverse-ssh

# Reload systemd
sudo systemctl daemon-reload

# Optional: Remove SSH key
sudo rm /root/.ssh/reverse_tunnel_key*
```

## 📚 Use Cases

1. **Remote System Administration**: Manage headless servers or IoT devices
2. **Behind NAT/Firewall**: Access machines behind restrictive networks
3. **Dynamic IP Addresses**: Maintain access to machines with changing IPs
4. **Development Testing**: Remote access to development machines
5. **Support and Maintenance**: Provide temporary access for troubleshooting

## 🤝 Contributing

Feel free to modify and enhance this system for your needs. Common enhancements:

- Add email notifications on connection failure
- Implement multiple server failover
- Add health check pings
- Create a web dashboard for monitoring

## 📄 License

Use at your own risk. This software is provided as-is without warranty.

## ⚠️ Legal Notice

Ensure you have proper authorization before establishing remote access to any system. Unauthorized access to computer systems is illegal in most jurisdictions.

---

**Created**: February 2026  
**Version**: 1.0  
**Platform**: Linux (systemd-based distributions)
