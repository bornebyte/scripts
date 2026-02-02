#!/bin/bash

# ============================================================================
# AUTH ANALYZER - Advanced Authentication Log Analysis Tool
# ============================================================================
# Analyzes /var/log/auth.log for user session activity with filtering,
# statistics, and beautiful output formatting.
# ============================================================================

# --- Configuration ---
LOG_FILE="/var/log/auth.log"
OUTPUT_FILE="/tmp/auth_analysis_$(date +%Y%m%d_%H%M%S).txt"
TEMP_FILE="/tmp/auth_temp_$$.log"

# --- Colors & Formatting ---
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_CYAN='\033[46m'

# --- Global Variables ---
DATE_FILTERS=""
DATE_RANGE=""
USER_FILTERS=""
SAVE_OUTPUT=0
LIST_DATES=0
STATS_ONLY=0
EXCLUDE_SYSTEM=0
MIN_DATE=""
MAX_DATE=""

# ============================================================================
# FUNCTIONS
# ============================================================================

show_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║           🔐 AUTH ANALYZER - Log Analysis Tool 🔐                  ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

show_help() {
    show_banner
    echo -e "${YELLOW}${BOLD}DESCRIPTION:${RESET}"
    echo -e "  Analyzes ${CYAN}$LOG_FILE${RESET} for user authentication activity"
    echo -e "  with advanced filtering, statistics, and beautiful output."
    echo
    echo -e "${YELLOW}${BOLD}USAGE:${RESET}"
    echo -e "  $0 ${GREEN}[OPTIONS]${RESET}"
    echo
    echo -e "${YELLOW}${BOLD}OPTIONS:${RESET}"
    echo -e "  ${GREEN}-d, --dates ${CYAN}<D1,D2,...>${RESET}"
    echo -e "      Filter by specific dates (e.g., 'Dec 7', 'Dec 5,Dec 6')"
    echo
    echo -e "  ${GREEN}-r, --range ${CYAN}<START:END>${RESET}"
    echo -e "      Filter by date range (e.g., 'Dec 1:Dec 31', 'Nov 1:Dec 8')"
    echo
    echo -e "  ${GREEN}-u, --users ${CYAN}<U1,U2,...>${RESET}"
    echo -e "      Filter by specific users (e.g., 'shubham', 'root,shubham')"
    echo
    echo -e "  ${GREEN}-s, --save${RESET}"
    echo -e "      Save output to file: $OUTPUT_FILE"
    echo
    echo -e "  ${GREEN}-l, --list-dates${RESET}"
    echo -e "      List all available dates in the log file"
    echo
    echo -e "  ${GREEN}-S, --stats-only${RESET}"
    echo -e "      Show only statistics summary (no detailed logs)"
    echo
    echo -e "  ${GREEN}-x, --exclude-system${RESET}"
    echo -e "      Exclude system users (root cron jobs, systemd)"
    echo
    echo -e "  ${GREEN}-h, --help${RESET}"
    echo -e "      Show this help message"
    echo
    echo -e "${YELLOW}${BOLD}EXAMPLES:${RESET}"
    echo -e "  ${DIM}# Show all activity for user shubham on Dec 7${RESET}"
    echo -e "  $0 -d 'Dec 7' -u 'shubham'"
    echo
    echo -e "  ${DIM}# Show activity in date range${RESET}"
    echo -e "  $0 -r 'Dec 1:Dec 8' -u 'shubham'"
    echo
    echo -e "  ${DIM}# List all available dates in log${RESET}"
    echo -e "  $0 --list-dates"
    echo
    echo -e "  ${DIM}# Show statistics only${RESET}"
    echo -e "  $0 --stats-only -u 'shubham'"
    echo
    exit 0
}

detect_date_range() {
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}${BOLD}✗ Error:${RESET} Log file not found: $LOG_FILE"
        exit 1
    fi

    # Get first and last dates from log
    local first_line=$(sudo head -1 "$LOG_FILE" 2>/dev/null)
    local last_line=$(sudo tail -1 "$LOG_FILE" 2>/dev/null)
    
    if [ -z "$first_line" ]; then
        echo -e "${RED}${BOLD}✗ Error:${RESET} Log file is empty or not readable"
        exit 1
    fi
    
    # Extract dates (handle both ISO and traditional formats)
    if [[ $first_line =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
        MIN_DATE="${BASH_REMATCH[1]}"
    else
        MIN_DATE=$(echo "$first_line" | awk '{print $1, $2}')
    fi
    
    if [[ $last_line =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
        MAX_DATE="${BASH_REMATCH[1]}"
    else
        MAX_DATE=$(echo "$last_line" | awk '{print $1, $2}')
    fi
}

list_available_dates() {
    echo -e "${CYAN}${BOLD}📅 Available Dates in Log File:${RESET}"
    echo -e "${DIM}────────────────────────────────────────${RESET}"
    
    sudo awk '
    {
        if ($1 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}/) {
            date = substr($1, 1, 10);
        } else {
            date = $1 " " $2;
        }
        dates[date]++;
    }
    END {
        for (d in dates) {
            printf "  %s%-20s%s (%s%d%s entries)\n", 
                "'$GREEN'", d, "'$RESET'", "'$DIM'", dates[d], "'$RESET'";
        }
    }
    ' "$LOG_FILE" | sort
    
    echo
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -d|--dates)
            DATE_FILTERS="$2"
            shift 2
            ;;
        -r|--range)
            DATE_RANGE="$2"
            if [[ ! "$DATE_RANGE" =~ : ]]; then
                echo -e "${RED}${BOLD}✗ Error:${RESET} Date range must be START:END (e.g., 'Dec 1:Dec 8')"
                exit 1
            fi
            shift 2
            ;;
        -u|--users)
            USER_FILTERS="$2"
            shift 2
            ;;
        -s|--save)
            SAVE_OUTPUT=1
            shift
            ;;
        -l|--list-dates)
            LIST_DATES=1
            shift
            ;;
        -S|--stats-only)
            STATS_ONLY=1
            shift
            ;;
        -x|--exclude-system)
            EXCLUDE_SYSTEM=1
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}${BOLD}✗ Error:${RESET} Unknown parameter: $1"
            echo -e "Use ${GREEN}--help${RESET} for usage information"
            exit 1
            ;;
    esac
done

# ============================================================================
# MAIN EXECUTION
# ============================================================================

show_banner

# Detect available date range
detect_date_range

# Handle --list-dates option
if [ "$LIST_DATES" -eq 1 ]; then
    list_available_dates
    echo -e "${CYAN}${BOLD}ℹ️  Date Range:${RESET} ${GREEN}$MIN_DATE${RESET} to ${GREEN}$MAX_DATE${RESET}"
    echo
    exit 0
fi

echo -e "${CYAN}${BOLD}📊 Analysis Configuration:${RESET}"
echo -e "${DIM}────────────────────────────────────────${RESET}"
echo -e "  Log File:      ${CYAN}$LOG_FILE${RESET}"
echo -e "  Available:     ${GREEN}$MIN_DATE${RESET} to ${GREEN}$MAX_DATE${RESET}"

# Prepare filter variables
START_TS=0
END_TS=9999999999

# Handle Date Range
if [ -n "$DATE_RANGE" ]; then
    START_DATE=$(echo "$DATE_RANGE" | cut -d ':' -f 1)
    END_DATE=$(echo "$DATE_RANGE" | cut -d ':' -f 2)
    
    START_TS=$(date -d "$START_DATE" +%s 2>/dev/null)
    END_TS=$(date -d "$END_DATE + 1 day" +%s 2>/dev/null)
    
    if [ -z "$START_TS" ] || [ -z "$END_TS" ]; then
        echo -e "${RED}${BOLD}✗ Error:${RESET} Invalid date format in range"
        exit 1
    fi
    
    echo -e "  Date Range:    ${YELLOW}$START_DATE${RESET} to ${YELLOW}$END_DATE${RESET}"
fi

# Handle Specific Dates
DATE_PATTERN=""
if [ -n "$DATE_FILTERS" ]; then
    CONVERTED_DATES=""
    OLD_IFS="$IFS"
    IFS=','
    for d in $DATE_FILTERS; do
        CONVERTED_DATE=$(date -d "$d" "+%Y-%m-%d" 2>/dev/null)
        if [ -z "$CONVERTED_DATE" ]; then
            echo -e "${RED}${BOLD}✗ Error:${RESET} Invalid date: $d"
            exit 1
        fi
        
        if [ -z "$CONVERTED_DATES" ]; then
            CONVERTED_DATES="$CONVERTED_DATE"
        else
            CONVERTED_DATES="$CONVERTED_DATES|$CONVERTED_DATE"
        fi
    done
    IFS="$OLD_IFS"
    DATE_PATTERN="$CONVERTED_DATES"
    echo -e "  Specific Dates: ${YELLOW}$DATE_FILTERS${RESET}"
fi

# Handle User Filter
USER_PATTERN=""
if [ -n "$USER_FILTERS" ]; then
    USER_PATTERN=$(echo "$USER_FILTERS" | sed 's/,/|/g')
    echo -e "  Users:         ${YELLOW}$USER_FILTERS${RESET}"
fi

# Handle Exclude System
EXCLUDE_PATTERN=""
if [ "$EXCLUDE_SYSTEM" -eq 1 ]; then
    EXCLUDE_PATTERN="CRON|systemd"
    echo -e "  Exclude:       ${DIM}System users (cron, systemd)${RESET}"
fi

echo -e "${DIM}────────────────────────────────────────${RESET}"
echo

# ============================================================================
# AWK PROCESSING
# ============================================================================

AWK_SCRIPT='
BEGIN {
    login_count = 0;
    logout_count = 0;
    total_count = 0;
    
    if (stats_only != 1) {
        printf "%s%s", cyan_bold, "🔍 Session Activity:\n";
        printf "%s", dim;
        printf "────────────────────────────────────────────────────────────────────────────\n";
        printf "%s", reset;
        printf "%s%-28s %-12s %-15s %s%s\n", 
            bold, "TIMESTAMP", "HOST", "USER", "EVENT", reset;
        printf "%s", dim;
        printf "────────────────────────────────────────────────────────────────────────────\n";
        printf "%s", reset;
    }
}

/session (opened|closed) for user/ {
    # Skip if exclude pattern matches
    if (exclude_pattern != "" && $0 ~ exclude_pattern) {
        next;
    }
    
    # Determine log format
    if ($1 ~ /^[0-9]/) {
        DATETIME = $1;
        HOST = $2;
        LOG_DATE_KEY = substr($1, 1, 10);
    } else {
        DATETIME = $1 " " $2 " " $3;
        HOST = $4;
        LOG_DATE_KEY = $1 " " $2;
    }
    
    # Extract user
    split($0, a, "for user ");
    USER = a[2];
    sub(/[( ].*/, "", USER);
    
    # Apply user filter
    if (user_regex != "" && USER !~ "^(" user_regex ")$") {
        next;
    }
    
    # Apply date range filter
    if (start_ts > 0) {
        ts_str = DATETIME;
        gsub(/[-T:]/, " ", ts_str);
        log_ts = mktime(substr(ts_str, 1, 19));
        if (log_ts < start_ts || log_ts >= end_ts) {
            next;
        }
    }
    
    # Apply specific date filter
    if (date_regex != "" && LOG_DATE_KEY !~ "^(" date_regex ")$") {
        next;
    }
    
    # Count and display
    total_count++;
    
    if ($0 ~ /session opened for user/) {
        login_count++;
        event_type = "LOGIN";
        event_color = green;
        icon = "🟢";
    } else {
        logout_count++;
        event_type = "LOGOUT";
        event_color = red;
        icon = "🔴";
    }
    
    # Store for statistics
    users[USER]++;
    
    if (stats_only != 1) {
        printf "%s%-28s%s %s%-12s%s %s%-15s%s %s%s %-6s%s\n",
            dim, DATETIME, reset,
            cyan, HOST, reset,
            yellow, USER, reset,
            event_color, icon, event_type, reset;
    }
}

END {
    if (stats_only != 1) {
        printf "%s", dim;
        printf "────────────────────────────────────────────────────────────────────────────\n";
        printf "%s", reset;
        printf "\n";
    }
    
    # Statistics
    printf "%s%s", cyan_bold, "📈 Statistics Summary:\n";
    printf "%s", dim;
    printf "────────────────────────────────────────────────────────────────────────────\n";
    printf "%s", reset;
    
    if (total_count == 0) {
        printf "%s%s", red_bold, "  ⚠️  No matching entries found!\n";
        printf "%s", reset;
        printf "\n";
        printf "%s", yellow;
        printf "  💡 Suggestions:\n";
        printf "%s", reset;
        printf "     • Check if the date range overlaps with available log data\n";
        printf "     • Use %s--list-dates%s to see available dates\n", green, reset;
        printf "     • Verify the username is correct\n";
        printf "\n";
    } else {
        printf "  %sTotal Events:%s      %s%d%s\n", bold, reset, green, total_count, reset;
        printf "  %sLogins:%s            %s🟢 %d%s\n", bold, reset, green, login_count, reset;
        printf "  %sLogouts:%s           %s🔴 %d%s\n", bold, reset, red, logout_count, reset;
        printf "\n";
        
        if (length(users) > 0) {
            printf "  %sActivity by User:%s\n", bold, reset;
            for (u in users) {
                printf "    • %s%-15s%s %s%3d%s events\n", 
                    yellow, u, reset, dim, users[u], reset;
            }
        }
        printf "\n";
    }
}
'

# Execute AWK
sudo cat "$LOG_FILE" 2>/dev/null | awk \
    -v cyan="$CYAN" \
    -v cyan_bold="$CYAN$BOLD" \
    -v green="$GREEN" \
    -v red="$RED" \
    -v yellow="$YELLOW" \
    -v blue="$BLUE" \
    -v bold="$BOLD" \
    -v dim="$DIM" \
    -v reset="$RESET" \
    -v red_bold="$RED$BOLD" \
    -v user_regex="$USER_PATTERN" \
    -v date_regex="$DATE_PATTERN" \
    -v start_ts="$START_TS" \
    -v end_ts="$END_TS" \
    -v exclude_pattern="$EXCLUDE_PATTERN" \
    -v stats_only="$STATS_ONLY" \
    "$AWK_SCRIPT" | tee "$TEMP_FILE"

# ============================================================================
# SAVE OUTPUT
# ============================================================================

if [ "$SAVE_OUTPUT" -eq 1 ]; then
    # Save without colors
    sudo cat "$LOG_FILE" 2>/dev/null | awk \
        -v user_regex="$USER_PATTERN" \
        -v date_regex="$DATE_PATTERN" \
        -v start_ts="$START_TS" \
        -v end_ts="$END_TS" \
        -v exclude_pattern="$EXCLUDE_PATTERN" \
        '
        BEGIN {
            printf "AUTH ANALYZER - Session Activity Report\n";
            printf "Generated: " strftime("%Y-%m-%d %H:%M:%S") "\n";
            printf "================================================================================\n\n";
            printf "%-28s %-12s %-15s %s\n", "TIMESTAMP", "HOST", "USER", "EVENT";
            printf "--------------------------------------------------------------------------------\n";
        }
        /session (opened|closed) for user/ {
            if (exclude_pattern != "" && $0 ~ exclude_pattern) next;
            
            if ($1 ~ /^[0-9]/) {
                DATETIME = $1; HOST = $2; LOG_DATE_KEY = substr($1, 1, 10);
            } else {
                DATETIME = $1 " " $2 " " $3; HOST = $4; LOG_DATE_KEY = $1 " " $2;
            }
            
            split($0, a, "for user "); USER = a[2]; sub(/[( ].*/, "", USER);
            
            if (user_regex != "" && USER !~ "^(" user_regex ")$") next;
            
            if (start_ts > 0) {
                ts_str = DATETIME; gsub(/[-T:]/, " ", ts_str);
                log_ts = mktime(substr(ts_str, 1, 19));
                if (log_ts < start_ts || log_ts >= end_ts) next;
            }
            
            if (date_regex != "" && LOG_DATE_KEY !~ "^(" date_regex ")$") next;
            
            event = ($0 ~ /session opened/) ? "LOGIN" : "LOGOUT";
            printf "%-28s %-12s %-15s %s\n", DATETIME, HOST, USER, event;
        }
        ' > "$OUTPUT_FILE"
    
    echo -e "${GREEN}${BOLD}✓ Saved:${RESET} ${CYAN}$OUTPUT_FILE${RESET}"
    echo
fi

# Cleanup
rm -f "$TEMP_FILE"

echo -e "${CYAN}${BOLD}✨ Analysis Complete!${RESET}"
echo
