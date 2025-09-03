# Makefile for TLB testbenches
# Supports both iverilog and VCS

# Simulator selection (iverilog or vcs)
SIM ?= iverilog

# Source files
PARAM_FILE = tlb_params.vh
SRC_FILES = tlb_storage.v tlb_lookup.v tlb_lru.v tlb_controller.v tlb.v

# Testbench files
TB_STORAGE = test_tlb_storage.v
TB_LOOKUP = test_tlb_lookup.v
TB_LRU = test_tlb_lru.v
TB_INTEGRATION = test_tlb_integration.v

# Output directories
BUILD_DIR = build
WAVE_DIR = waves
LOG_DIR = logs

# Create directories
$(shell mkdir -p $(BUILD_DIR) $(WAVE_DIR) $(LOG_DIR))

# Simulator specific settings
ifeq ($(SIM), iverilog)
    COMPILE = iverilog -g2012 -Wall -I.
    RUN = vvp
    EXT = .vvp
else ifeq ($(SIM), vcs)
    COMPILE = vcs -sverilog +v2k -debug_all -I.
    RUN = 
    EXT = .simv
endif

# Default target
all: test_all

# Individual unit tests
test_storage: $(BUILD_DIR)/test_storage$(EXT)
	@echo "=== Running TLB Storage Test ==="
	$(RUN) $(BUILD_DIR)/test_storage$(EXT) | tee $(LOG_DIR)/test_storage.log
	@echo ""

test_lookup: $(BUILD_DIR)/test_lookup$(EXT)
	@echo "=== Running TLB Lookup Test ==="
	$(RUN) $(BUILD_DIR)/test_lookup$(EXT) | tee $(LOG_DIR)/test_lookup.log
	@echo ""

test_lru: $(BUILD_DIR)/test_lru$(EXT)
	@echo "=== Running TLB LRU Test ==="
	$(RUN) $(BUILD_DIR)/test_lru$(EXT) | tee $(LOG_DIR)/test_lru.log
	@echo ""

test_integration: $(BUILD_DIR)/test_integration$(EXT)
	@echo "=== Running TLB Integration Test ==="
	$(RUN) $(BUILD_DIR)/test_integration$(EXT) | tee $(LOG_DIR)/test_integration.log
	@if [ -f tlb_integration.vcd ]; then mv tlb_integration.vcd $(WAVE_DIR)/; fi
	@echo ""

# Run all tests
test_all: test_storage test_lookup test_lru test_integration
	@echo "========================================="
	@echo "All tests completed. Check logs directory for details."
	@echo "========================================="
	@grep -h "ALL TESTS" $(LOG_DIR)/*.log || true
	@echo "========================================="

# Unit test targets
unit_tests: test_storage test_lookup test_lru
	@echo "=== Unit tests completed ==="

# Compilation rules
$(BUILD_DIR)/test_storage$(EXT): $(TB_STORAGE) tlb_storage.v $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_STORAGE) tlb_storage.v

$(BUILD_DIR)/test_lookup$(EXT): $(TB_LOOKUP) tlb_lookup.v $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_LOOKUP) tlb_lookup.v

$(BUILD_DIR)/test_lru$(EXT): $(TB_LRU) tlb_lru.v $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_LRU) tlb_lru.v

$(BUILD_DIR)/test_integration$(EXT): $(TB_INTEGRATION) $(SRC_FILES) $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_INTEGRATION) $(SRC_FILES)

# View waveforms (for iverilog with gtkwave)
wave: $(WAVE_DIR)/tlb_integration.vcd
	gtkwave $(WAVE_DIR)/tlb_integration.vcd &

# Coverage report (if using VCS)
coverage:
ifeq ($(SIM), vcs)
	urg -dir simv.vdb -report coverage_report
else
	@echo "Coverage is only available with VCS"
endif

# Clean
clean:
	rm -rf $(BUILD_DIR)/* $(LOG_DIR)/* $(WAVE_DIR)/*
	rm -f *.vcd *.log
	rm -rf simv* csrc urg* *.key DVE* .vcs*

# Help
help:
	@echo "TLB Testbench Makefile"
	@echo "======================"
	@echo "Targets:"
	@echo "  all            - Run all tests (default)"
	@echo "  test_all       - Run all tests"
	@echo "  unit_tests     - Run only unit tests"
	@echo "  test_storage   - Run storage module test"
	@echo "  test_lookup    - Run lookup module test"
	@echo "  test_lru       - Run LRU module test"
	@echo "  test_integration - Run integration test"
	@echo "  wave           - View waveforms (requires gtkwave)"
	@echo "  coverage       - Generate coverage report (VCS only)"
	@echo "  clean          - Clean all generated files"
	@echo "  help           - Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  SIM=iverilog   - Use Icarus Verilog (default)"
	@echo "  SIM=vcs        - Use Synopsys VCS"
	@echo ""
	@echo "Examples:"
	@echo "  make test_all"
	@echo "  make test_integration SIM=vcs"
	@echo "  make clean"

.PHONY: all test_all unit_tests test_storage test_lookup test_lru test_integration wave coverage clean help