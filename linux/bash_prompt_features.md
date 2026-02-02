# 🚀 Enhanced Bash Prompt Features

Your `.bashrc` has been customized with a feature-rich, Kali Linux-style prompt!

## 📊 Prompt Features (Line 1)

### ✅ Requested Features:
1. **Two-line prompt**: All info on line 1, command input on line 2
2. **Battery percentage**: 🔋 Shows battery level with color coding:
   - Green (≥80%), Yellow (40-79%), Red (<40%)
   - ⚡ indicator when charging
3. **Command execution time**: ⏱ Shows how long the previous command took
4. **Exit status**: ✔ (success) or ✘ with error code (failure)

### 🎁 Additional Features Added:
5. **User & Hostname**: Shows current user and computer name (green)
6. **Current Directory**: Full path in blue
7. **Git Information**: 
   - Branch name in purple
   - ✓ = staged changes
   - ✗ = unstaged/untracked files
   - ↑ = ahead of remote
   - ↓ = behind remote
8. **Current Time**: [HH:MM:SS] in cyan
9. **Background Jobs**: ⚙️ Shows count of running jobs
10. **Python Virtual Environment**: Shows active venv
11. **History Number**: Command number in history [!123]

## 🎨 Prompt Format

```
username@hostname ~/path/to/dir (git-branch✓) 🔋85%⚡ [14:32:45] ⚙️ 2 ✔ ⏱ 2s [!1234]
┌─[(venv) ]
└─$ your-command-here
```

## 🛠️ Enhanced Aliases

### Navigation:
- `ll` - Detailed list view
- `la` - List all including hidden
- `..` / `...` / `....` - Quick parent directory navigation

### System:
- `df`, `du`, `free` - Show sizes in human-readable format
- `ports` - Show all open ports
- `psg` - Search processes by name
- `mkdir` - Always create parent directories
- `top` - Uses htop if available

### Safety:
- `rm`, `cp`, `mv` - Interactive mode (asks before overwriting)

### Quick Access:
- `bashrc` - Edit .bashrc file
- `reload` - Reload bash configuration

## 📦 Useful Functions

- `mkcd <dir>` - Make directory and cd into it
- `take <dir>` - Same as mkcd
- `backup <file>` - Create timestamped backup
- `extract <archive>` - Auto-extract any archive format
- `qfind <name>` - Quick find files by name
- `duh` - Show top 20 largest items in current directory
- `killp <name>` - Find and kill process by name
- `publicip` - Show your public IP address
- `weather [location]` - Show weather (optional location)

## ⚡ Enhanced Shell Behavior

- **Auto-correct typos** in directory names
- **Case-insensitive** tab completion
- **Recursive globbing** with `**` pattern
- **Better history**:
  - Timestamps for all commands
  - Ignores duplicates
  - Larger history size (50,000 commands)
  - Ignores common commands (ls, cd, etc.)
- **Colored man pages** for better readability
- **Better less pager** with colors

## 🔄 How to Apply

Reload your bash configuration:
```bash
source ~/.bashrc
```
Or simply type:
```bash
reload
```

## 📝 Customization Tips

### Change Colors:
Edit the PS1 variable in `.bashrc`. Color codes:
- `\[\e[1;32m\]` - Bold Green
- `\[\e[1;34m\]` - Bold Blue
- `\[\e[1;35m\]` - Bold Magenta
- `\[\e[1;36m\]` - Bold Cyan
- `\[\e[1;33m\]` - Bold Yellow
- `\[\e[1;31m\]` - Bold Red
- `\[\e[0m\]` - Reset

### Hide Specific Elements:
Comment out sections in the PS1 variable you don't want.

### Battery Path:
If battery doesn't show, check your battery path:
```bash
ls /sys/class/power_supply/
```
Update `get_battery()` function with correct path.

## 🎯 Pro Tips

1. Use **Ctrl+R** for reverse history search (enhanced with fzf if installed)
2. Use **!!** to repeat last command
3. Use **!$** to reference last argument
4. Use **cd -** to go back to previous directory
5. Try `weather` command for quick weather info
6. Use `extract` for any compressed file

Enjoy your supercharged terminal! 🎉
