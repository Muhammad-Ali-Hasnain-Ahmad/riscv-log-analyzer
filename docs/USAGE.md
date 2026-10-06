# Project Usage Guide
This project is a shell-based tool that processes RISC-V
simulation log files by a `Makefile`. It handles checking system prerequisites, validating shell scripts, executing workflows with test logs, and managing output summary directories.
## 🚀 Quick Start

To see a list of all available commands and their descriptions directly in terminal, run:

```bash
make help
```

---

## 🛠 Available Targets

### 1. Environment Verification
Before running scripts for the first time, check that local environment has the required core programs installed:
```bash
make setup
```
* **What it does:** Scans the system path for `bash`, `grep`, `awk`, and `shellcheck`. It will warn visually if any required tool is missing.

### 2. Code Linting & Validation
To analyze shell scripts for hidden syntax bugs, unquoted variables, or performance issues before executing them:
```bash
make lint
```
* **What it does:** Executes `shellcheck` across all `.sh` scripts in the `scripts/` directory. If the script is 100% compliant, it returns a clean, silent success block.

### 3. Execution & Testing
To compile/prepare shell scripts and execute them directly into current terminal screen:
```bash
make test
```
* **What it does:** Prepares scripts as runnable binaries inside `bin/` and triggers main script utilizing the sample telemetry data in `logs/input.log`.

### 4. Summary Report Generation
To execute analytical workflow quietly and pipeline the absolute outputs into a structured database or directory structure:
```bash
make report
```
* **What it does:** Executes the main script with log arguments and redirects terminal output straight into `output/summary_report.csv`.

### 5. Repository Cleaning
To wipe out temporary artifacts and flush generated files to start fresh:
```bash
make clean
```
* **What it does:** Safely flushes the `bin/` directory and empties the contents inside `output/` without breaking the folder framework itself.

---