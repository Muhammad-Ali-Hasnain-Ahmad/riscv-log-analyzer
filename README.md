# RISC-V Log Analyzer (`riscv-log-analyzer`)

A lightweight, automated Bash-based utility designed to process, parse, and analyze RISC-V simulation log files. It extracts critical execution metrics, test outcomes, error reports, and timing statistics, generating both quick command-line summaries and formatted text reports.

---

## Features

- **Log Parsing**: Automatically parses timestamped log lines for test states (`START`, `PASS`, `FAIL`, `SKIP`), errors, and warnings.
- **Metric Extraction**: Computes total executed instructions, total tests run, pass rates, failure details, and overall execution time.
- **Automated Workflows**: Built-in `Makefile` for automated setup, testing, analysis, and report generation.
- **Error Detection**: Returns standard failure exit codes when errors or test failures are detected for CI/CD integration.

---

## Sample Output

=== RISC-V Simulation Log Analysis ===
Analysis date: 2026-10-06 17:42:36
--- Results Summary ---
Total Tests Run      : 10
Total PASS           : 5 (50.00%)
Total FAIL           : 2 (20.00%)
Total SKIP           : 3 (30.00%)

Execution Metrics:
  Min Run Time       : 0.02s (Pipeline Register IF)
  Max Run Time       : 5.12s (Register File Read)
  Avg Run Time       : 3.98s

Failing Test Details:
  - ALU Operation
  - Jump Logic

Individual Test Executions:
------------------------------------
  Instruction Fetch              [PASS] 4.92s
  ALU Operation                  [FAIL] 5.03s
  Data Memory Access             [PASS] 4.88s
  Register File Read             [PASS] 5.12s
  Register File Write            [SKIP] 0.05s
  Branch Control                 [PASS] 4.97s
  Jump Logic                     [FAIL] 5.01s
  Immediate Generation           [PASS] 4.95s
  Program Counter Increment      [SKIP] 4.89s
  Pipeline Register IF           [SKIP] 0.02s
====================================
--- Verdict: FAIL ---
Exit code: 1

## Directory Structure

```text
riscv-log-analyzer/
├── README.md              # Project documentation and quick start guide
├── USAGE.md               # Detailed command-line reference
├── Makefile               # Build and execution automation
├── .gitignore             # Exclusion rules for temporary/build artifacts
├── scripts/
│   ├── setup_env.sh       # Environment verification and directory setup
│   ├── analyze.sh         # Core log analysis script
│   └── generate_report.sh # Structured report generator script
└── test_data/
    ├── sample_sim.log     # Sample log file with errors and failures
    └── sample_pass.log    # Sample log file with passing execution