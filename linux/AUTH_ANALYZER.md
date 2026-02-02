# 🔐 Auth Analyzer - Authentication Log Analysis Tool

A powerful and beautiful bash script for analyzing authentication logs (`/var/log/auth.log`) with advanced filtering, statistics, and professional output formatting.

## ✨ Features

- 🎨 **Beautiful UI** - Color-coded output with emojis and box-drawing characters
- 📊 **Statistics** - Comprehensive analytics including login/logout counts and per-user breakdowns
- 🔍 **Flexible Filtering** - Filter by date ranges, specific dates, and users
- 📅 **Date Discovery** - Automatically detect and list available dates in logs
- 🚫 **System Filter** - Exclude noisy system events (cron, systemd)
- 💾 **Export Reports** - Save clean plain-text reports for documentation
- 📈 **Quick Stats** - Stats-only mode for rapid overview
- ⚡ **Fast & Efficient** - Single-pass AWK processing for speed

## 📋 Requirements

- Linux system with bash
- Access to `/var/log/auth.log` (requires sudo)
- AWK (usually pre-installed)
- Terminal with ANSI color support

## 🚀 Quick Start

### Make the script executable
```bash
chmod +x auth_analyzer.sh
```

### List available dates in your log
```bash
./auth_analyzer.sh --list-dates
```

### Analyze a specific date for a user
```bash
./auth_analyzer.sh -d 'Dec 7' -u 'shubham'
```

### Analyze a date range
```bash
./auth_analyzer.sh -r 'Dec 1:Dec 8' -u 'shubham'
```

## 📖 Usage

```bash
./auth_analyzer.sh [OPTIONS]
```

## 🎛️ Options

| Option | Long Form | Description | Example |
|--------|-----------|-------------|---------|
| `-d` | `--dates` | Filter by specific dates (comma-separated) | `-d 'Dec 7'` or `-d 'Dec 5,Dec 6,Dec 7'` |
| `-r` | `--range` | Filter by date range (START:END) | `-r 'Dec 1:Dec 31'` |
| `-u` | `--users` | Filter by users (comma-separated) | `-u 'shubham'` or `-u 'root,shubham'` |
| `-s` | `--save` | Save output to timestamped file | `-s` |
| `-l` | `--list-dates` | List all available dates in log | `-l` |
| `-S` | `--stats-only` | Show only statistics (no detailed logs) | `-S` |
| `-x` | `--exclude-system` | Exclude system users (cron, systemd) | `-x` |
| `-h` | `--help` | Show help message | `-h` |

## 💡 Examples

### Example 1: Check your activity today
```bash
./auth_analyzer.sh -d 'Dec 8' -u 'shubham'
```

**Output:**
```
╔════════════════════════════════════════════════════════════════════╗
║           🔐 AUTH ANALYZER - Log Analysis Tool 🔐                 ║
╚════════════════════════════════════════════════════════════════════╝

📊 Analysis Configuration:
────────────────────────────────────────────────────────────────────
  Log File:      /var/log/auth.log
  Available:     2025-12-07 to 2025-12-08
  Specific Dates: Dec 8
  Users:         shubham
────────────────────────────────────────────────────────────────────

🔍 Session Activity:
────────────────────────────────────────────────────────────────────
TIMESTAMP                    HOST         USER            EVENT
────────────────────────────────────────────────────────────────────
2025-12-08T09:15:23.123456+05:30 Node         shubham         🟢 LOGIN
2025-12-08T18:30:45.654321+05:30 Node         shubham         🔴 LOGOUT
────────────────────────────────────────────────────────────────────

📈 Statistics Summary:
────────────────────────────────────────────────────────────────────
  Total Events:      2
  Logins:            🟢 1
  Logouts:           🔴 1

  Activity by User:
    • shubham           2 events

✨ Analysis Complete!
```

### Example 2: Weekly overview with statistics only
```bash
./auth_analyzer.sh -r 'Dec 1:Dec 8' --stats-only
```

### Example 3: Find what dates have data
```bash
./auth_analyzer.sh --list-dates
```

**Output:**
```
📅 Available Dates in Log File:
────────────────────────────────────────
  2025-12-07           (603 entries)
  2025-12-08           (130 entries)

ℹ️  Date Range: 2025-12-07 to 2025-12-08
```

### Example 4: Clean user sessions (exclude system noise)
```bash
./auth_analyzer.sh -d 'Dec 7' --exclude-system
```

### Example 5: Generate a report for multiple users
```bash
./auth_analyzer.sh -r 'Dec 1:Dec 31' -u 'shubham,john,alice' --save
```

### Example 6: Quick stats for all users
```bash
./auth_analyzer.sh -r 'Dec 7:Dec 8' --stats-only
```

## 📊 Understanding the Output

### Session Activity Table
- **TIMESTAMP**: When the event occurred (ISO 8601 format)
- **HOST**: Hostname where the event occurred
- **USER**: Username associated with the event
- **EVENT**: 
  - 🟢 **LOGIN** - User session opened
  - 🔴 **LOGOUT** - User session closed

### Statistics Summary
- **Total Events**: Combined count of all login/logout events
- **Logins**: Number of session opened events
- **Logouts**: Number of session closed events
- **Activity by User**: Per-user event breakdown

## 🔧 Troubleshooting

### No matching entries found?

The script will show helpful suggestions:

```
📈 Statistics Summary:
────────────────────────────────────────────────────────────────────
  ⚠️  No matching entries found!

  💡 Suggestions:
     • Check if the date range overlaps with available log data
     • Use --list-dates to see available dates
     • Verify the username is correct
```

**Common causes:**
1. **Date out of range**: The log file only keeps recent data. Use `--list-dates` to see what's available.
2. **Wrong username**: Usernames are case-sensitive. Check spelling.
3. **No activity**: The user simply didn't log in/out during that period.

### Permission denied?

The script needs sudo access to read `/var/log/auth.log`. You'll be prompted for your password.

### Colors not showing?

Make sure your terminal supports ANSI colors. Most modern terminals do by default.

## 📁 Saved Reports

When using the `--save` option, reports are saved to:
```
/tmp/auth_analysis_YYYYMMDD_HHMMSS.txt
```

The saved file contains clean, plain-text output without colors, perfect for:
- Documentation
- Audit trails
- Email attachments
- Long-term archival

## 🎯 Common Use Cases

### Security Audit
```bash
# Check all login activity for the past week
./auth_analyzer.sh -r 'Dec 1:Dec 8' --exclude-system --save
```

### User Monitoring
```bash
# Monitor specific user's activity
./auth_analyzer.sh -u 'username' --stats-only
```

### Daily Check
```bash
# Quick daily overview
./auth_analyzer.sh -d 'today' --stats-only
```

### Investigation
```bash
# Detailed analysis of specific date
./auth_analyzer.sh -d 'Dec 7' -u 'shubham'
```

## 🔒 Security Notes

- The script requires **sudo** to read `/var/log/auth.log`
- It only **reads** the log file, never modifies it
- Saved reports are created with your user permissions (not root)
- No data is sent over the network

## 🐛 Known Limitations

- Only analyzes `/var/log/auth.log` (not rotated logs like `auth.log.1`)
- Date parsing requires GNU date (standard on Linux)
- Requires sudo access to read auth logs

## 📝 Date Format Examples

The script accepts flexible date formats:

- `'Dec 7'` - Month and day
- `'Dec 7, 2025'` - Full date
- `'2025-12-07'` - ISO format
- `'yesterday'` - Relative dates (if supported by your system)

## 🤝 Contributing

Found a bug or have a feature request? Feel free to modify the script to suit your needs!

## 📄 License

This script is provided as-is for educational and administrative purposes.

## 👤 Author

Created for system administrators and security professionals who need quick, beautiful authentication log analysis.

---

**Happy Analyzing! 🔐✨**
