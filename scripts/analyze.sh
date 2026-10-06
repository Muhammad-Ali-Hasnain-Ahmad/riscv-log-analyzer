#!/usr/bin/env bash
# Exit immediately if a command exits with a non-zero status, 
# if an uninitialised variable is used, or if a piped command fails.
set -euo pipefail

# --- Default Configuration ---
LOG_FILE=""
FORMAT="text"
OUTPUT_FILE=""
VERBOSE=false

# --- Color Definitions ---
# Only applied if outputting to standard terminal (stdout)
NC='\033[0m'        # No Color
RED='\033[0;31m'     # Red
GREEN='\033[0;32m'   # Green
YELLOW='\033[0;33m'  # Yellow
BRED='\033[1;31m'    # Bold Red
BGREEN='\033[1;32m'  # Bold Green

# --- Usage / Help Function ---
print_help() {
    cat << EOF
Usage: $(basename "$0") <log_file_path> [OPTIONS]

Arguments:
  \$1                       Path to the log file (Required)

Options:
  --format [text|csv]      Output format: 'text' or 'csv' (Default: text)
  --output <path>          Redirect output to a file instead of stdout
  --verbose                Enable detailed execution tracing logs
  -h, --help               Print usage information
EOF
}

# --- Argument Parsing & Validation ---
if [ $# -eq 0 ]; then
    echo "Error: Missing log file path." >&2
    print_help
    exit 1
fi

LOG_FILE="$1"
shift

while [ $# -gt 0 ]; do
    case "$1" in
        --format)
            if [ -z "${2:-}" ] || [[ ! "$2" =~ ^(text|csv)$ ]]; then
                echo "Error: --format requires 'text' or 'csv'." >&2
                exit 1
            fi
            FORMAT="$2"
            shift 2
            ;;
        --output)
            if [ -z "${2:-}" ]; then
                echo "Error: --output requires a file path." >&2
                exit 1
            fi
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'." >&2
            print_help
            exit 1
            ;;
    esac
done

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' does not exist or is not a regular file." >&2
    exit 1
fi

# --- Core Logic & Analysis Function ---
analyze_log() {
    local file="$1"
    
    # Process the log file using POSIX-compliant awk strings to guarantee compatibility.
    awk '
    BEGIN {
        total = 0; pass = 0; fail = 0; skip = 0;
        min_t = 999999; max_t = -1; sum_t = 0; count_t = 0;
        min_test = "None"; max_test = "None";
        failing_list = "";
    }
    {
        # Check if the line ends with a time parenthesis like (4.92s) or (0.00s)
        if ($0 ~ /\([0-9.]+[^)]*\)$/) {
            
            # Safely isolate the numeric time value using index positions
            open_paren = index($0, " (")
            time_str = substr($0, open_paren + 2)
            sub(/[sS]\)$/, "", time_str)
            time_val = time_str + 0; # Convert explicitly to a floating number
            
            # Extract log status string (e.g., PASS, FAIL, SKIP, START)
            status = $4;
            sub(/:$/, "", status); # Strip trailing colons safely
            
            # Isolate test name between status tag and time bracket
            test_start = index($0, status) + length(status) + 2;
            test_end = open_paren;
            test_name = substr($0, test_start, test_end - test_start);

            # Ignore START blocks for evaluation counters
            if (status != "START") {
                total++;
                sum_t += time_val;
                count_t++;
                
                # Check and store minimum time alongside test name
                if (time_val < min_t) {
                    min_t = time_val;
                    min_test = test_name;
                }
                # Check and store maximum time alongside test name
                if (time_val > max_t) {
                    max_t = time_val;
                    max_test = test_name;
                }
                
                if (status == "PASS") pass++;
                else if (status == "FAIL") {
                    fail++;
                    failing_list = (failing_list == "" ? test_name : failing_list "," test_name);
                }
                else if (status == "SKIP") skip++;
                
                # Cache metric arrays for index loop generation
                test_records[total] = test_name;
                test_status[total] = status;
                test_times[total] = time_val;
            }
        }
    }
    END {
        if (total == 0) { min_t = 0; max_t = 0; avg_t = 0; }
        else { avg_t = sum_t / count_t; }
        
        p_rate = (total > 0) ? (pass / total) * 100 : 0;
        f_rate = (total > 0) ? (fail / total) * 100 : 0;
        s_rate = (total > 0) ? (skip / total) * 100 : 0;

        print "TOTAL=" total;
        print "PASS=" pass;
        print "FAIL=" fail;
        print "SKIP=" skip;
        printf "PASS_RATE=%.2f%%\n", p_rate;
        printf "FAIL_RATE=%.2f%%\n", f_rate;
        printf "SKIP_RATE=%.2f%%\n", s_rate;
        printf "MIN_TIME=%.2fs (%s)\n", (min_t == 999999 ? 0 : min_t), min_test;
        printf "MAX_TIME=%.2fs (%s)\n", (max_t == -1 ? 0 : max_t), max_test;
        printf "AVG_TIME=%.2fs\n", avg_t;
        print "FAILING_TESTS=" failing_list;
        
        print "---DETAILED_RECORDS_START---";
        for (i = 1; i <= total; i++) {
            print test_records[i] "|" test_status[i] "|" test_times[i] "s";
        }
    }
    ' "$file"
}

# --- Format Execution Data ---
generate_report() {
    local run_date
    run_date=$(date +"%Y-%m-%d %H:%M:%S")
    
    local verdict="PASS"
    local code=0
    local color_verdict="${BGREEN}PASS${NC}"
    
    if [ "$FAIL" -gt 0 ]; then
        verdict="FAIL"
        code=1
        color_verdict="${BRED}FAIL${NC}"
    fi

    # Disable colors if writing to a file to prevent escape character pollution
    if [ -n "$OUTPUT_FILE" ]; then
        NC='' RED='' GREEN='' YELLOW='' BRED='' BGREEN=''
        color_verdict="$verdict"
    fi

    if [ "$FORMAT" = "text" ]; then
        # Using echo -e safely interprets colors without option collisions
        echo "=== RISC-V Simulation Log Analysis ==="
        echo "Analysis date: $run_date"
        echo "--- Results Summary ---"
        echo "Total Tests Run      : $TOTAL"
        echo -e "Total PASS           : ${GREEN}${PASS}${NC} (${PASS_RATE})"
        echo -e "Total FAIL           : ${RED}${FAIL}${NC} (${FAIL_RATE})"
        echo -e "Total SKIP           : ${YELLOW}${SKIP}${NC} (${SKIP_RATE})"
        echo ""
        echo "Execution Metrics:"
        echo "  Min Run Time       : $MIN_TIME"
        echo "  Max Run Time       : $MAX_TIME"
        echo "  Avg Run Time       : $AVG_TIME"
        echo ""
        echo "Failing Test Details:"
        
        if [ -n "$FAILING_TESTS" ]; then 
            echo "$FAILING_TESTS" | tr ',' '\n' | while read -r line; do
                if [ -n "$line" ]; then
                    echo -e "  - ${RED}${line}${NC}"
                fi
            done
        else 
            echo "  None"
        fi
        
        echo ""
        echo "Individual Test Executions:"
        echo "------------------------------------"
        
        if [ -n "$DETAILED_DATA" ]; then
            echo "$DETAILED_DATA" | while IFS='|' read -r name status duration; do
                if [ -n "$name" ]; then
                    local s_color="$NC"
                    case "$status" in
                        PASS) s_color="$GREEN" ;;
                        FAIL) s_color="$RED" ;;
                        SKIP) s_color="$YELLOW" ;;
                    esac
                    # Format individual execution lines safely using a static string pattern
                    printf "  %-30s [" "$name"
                    echo -e -n "${s_color}${status}${NC}"
                    printf "] %s\n" "$duration"
                fi
            done
        fi
        
        echo "===================================="
        echo -e "--- Verdict: ${color_verdict} ---"
        echo "Exit code: $code"

    elif [ "$FORMAT" = "csv" ]; then
        echo "# === RISC-V Simulation Log Analysis ==="
        echo "# Analysis date: $run_date"
        echo "# --- Results Summary ---"
        echo "Metric,Value/Details"
        echo "Total Tests,$TOTAL"
        echo "PASS Count,$PASS"
        echo "PASS Rate,$PASS_RATE"
        echo "FAIL Count,$FAIL"
        echo "FAIL Rate,$FAIL_RATE"
        echo "SKIP Count,$SKIP"
        echo "SKIP Rate,$SKIP_RATE"
        echo "Min Execution Time,\"$MIN_TIME\""
        echo "Max Execution Time,\"$MAX_TIME\""
        echo "Avg Execution Time,$AVG_TIME"
        echo "Failing Tests,\"$(echo "$FAILING_TESTS" | tr ',' ';')\""
        echo "Verdict,$verdict"
        echo "Exit Code,$code"
        echo ""
        echo "Test Name,Status,Execution Time"
        if [ -n "$DETAILED_DATA" ]; then
            echo "$DETAILED_DATA" | while IFS='|' read -r name status duration; do
                [ -n "$name" ] && echo "\"$name\",$status,$duration"
            done
        fi
    fi
}

# --- Execute Analysis Core Pipeline ---
if [ "$VERBOSE" = true ]; then echo "[VERBOSE] Processing metrics..." >&2; fi

RAW_METRICS=$(analyze_log "$LOG_FILE")

TOTAL=$(echo "$RAW_METRICS" | grep '^TOTAL=' | cut -d= -f2 || echo "0")
PASS=$(echo "$RAW_METRICS" | grep '^PASS=' | cut -d= -f2 || echo "0")
FAIL=$(echo "$RAW_METRICS" | grep '^FAIL=' | cut -d= -f2 || echo "0")
SKIP=$(echo "$RAW_METRICS" | grep '^SKIP=' | cut -d= -f2 || echo "0")
PASS_RATE=$(echo "$RAW_METRICS" | grep '^PASS_RATE=' | cut -d= -f2 || echo "0.00%")
FAIL_RATE=$(echo "$RAW_METRICS" | grep '^FAIL_RATE=' | cut -d= -f2 || echo "0.00%")
SKIP_RATE=$(echo "$RAW_METRICS" | grep '^SKIP_RATE=' | cut -d= -f2 || echo "0.00%")
MIN_TIME=$(echo "$RAW_METRICS" | grep '^MIN_TIME=' | cut -d= -f2- || echo "0.00s")
MAX_TIME=$(echo "$RAW_METRICS" | grep '^MAX_TIME=' | cut -d= -f2- || echo "0.00s")
AVG_TIME=$(echo "$RAW_METRICS" | grep '^AVG_TIME=' | cut -d= -f2 || echo "0.00s")
FAILING_TESTS=$(echo "$RAW_METRICS" | grep '^FAILING_TESTS=' | cut -d= -f2 || echo "")
DETAILED_DATA=$(echo "$RAW_METRICS" | sed -n '/---DETAILED_RECORDS_START---/,$p' | tail -n +2 || echo "")
if [ -n "$OUTPUT_FILE" ]; then
generate_report > "$OUTPUT_FILE"
else
generate_report
fi
if [ "${FAIL:-0}" -gt 0 ]; then
exit 1
else
exit 0
fi