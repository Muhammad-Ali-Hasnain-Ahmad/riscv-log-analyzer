SCR_DIR = scripts
BIN_DIR = bin
LOG_DIR = test_data
OUTPUT_DIR = output

SCR = $(SCR_DIR)/analyze.sh

TARGET = $(SCR:$(SCR_DIR)/%.sh=$(BIN_DIR)/%)
LOG_ARGS = $(LOG_DIR)/sample_sim.log
LINTER = shellcheck
REQUIRED_TOOLS = bash grep awk $(LINTER)
.PHONY: all clean test dirs lint report help setup

all: dirs $(TARGET)
dirs:
	@mkdir -p $(BIN_DIR)
	
$(BIN_DIR)/%: $(SCR_DIR)/%.sh
	@cp $< $@
	@chmod +x $@
lint: ## Check shell scripts for hidden bugs/syntax errors using shellcheck
	$(LINTER) $(SCR)

setup: ## Check that all required system tools (bash, grep, awk, shellcheck) are installed
	@echo 'Checking system dependencies...'
	@errors=0; \
	for tool in $(REQUIRED_TOOLS); do \
		if ! command -v $$tool >/dev/null 2>&1; then \
			echo "  \033[31m[MISSING]\033[0m $$tool is not installed."; \
			errors=$$((errors + 1)); \
		else \
			echo "  \033[32m[FOUND]\033[0m   $$tool is installed."; \
		fi; \
	done; \
	if [ $$errors -ne 0 ]; then \
		echo ""; \
		echo "\033[31mSetup failed: Please install the missing tools listed above.\033[0m"; \
		exit 1; \
	fi; \
	echo ""; \
	echo "\033[32mSetup complete! All required tools are ready.\033[0m"

report:all ## Generates a summary report file inside the output/ directory
	-./$(BIN_DIR)/analyze $(LOG_ARGS) > $(OUTPUT_DIR)/summary_report.csv

test:all ## Runs main script directly to the terminal
	-./$(BIN_DIR)/analyze $(LOG_ARGS)

help: ## Display this help message showing all available options
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
