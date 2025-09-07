# Makefile for TLB testbenches
# Supports both iverilog and VCS

# Simulator selection (iverilog or vcs)
SIM ?= iverilog

# Source files
PARAM_FILE = tlb_params.vh
SRC_FILES = tlb_storage.v tlb_lookup.v tlb_lru.v tlb_controller.v tlb.v ptw.v memory.v

# Testbench files
TB_STORAGE = test_tlb_storage.v
TB_LOOKUP = test_tlb_lookup.v
TB_LRU = test_tlb_lru.v
TB_PTW = test_ptw.v
TB_MEMORY = test_memory.v
TB_INTEGRATION_MEMORY_PTW = test_integration_memory_ptw.v
TB_INTEGRATION_TLB = test_integration_tlb.v

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

test_ptw: $(BUILD_DIR)/test_ptw$(EXT)
	@echo "=== Running PTW Test ==="
	$(RUN) $(BUILD_DIR)/test_ptw$(EXT) | tee $(LOG_DIR)/test_ptw.log
	@echo ""

test_memory: $(BUILD_DIR)/test_memory$(EXT)
	@echo "=== Running MEMORY Test ==="
	$(RUN) $(BUILD_DIR)/test_memory$(EXT) | tee $(LOG_DIR)/test_memory.log
	@echo ""

test_integration_memory_ptw: $(BUILD_DIR)/test_integration_memory_ptw$(EXT)
	@echo "=== Running MEMORY PTW Integration Test ==="
	$(RUN) $(BUILD_DIR)/test_integration_memory_ptw$(EXT) | tee $(LOG_DIR)/test_integration_memory_ptw.log
	@if [ -f test_integration_memory_ptw.vcd ]; then mv test_integration_memory_ptw.vcd $(WAVE_DIR)/; fi
	@echo ""

test_integration_tlb: $(BUILD_DIR)/test_integration_tlb$(EXT)
	@echo "=== Running TLB Integration Test ==="
	$(RUN) $(BUILD_DIR)/test_integration_tlb$(EXT) | tee $(LOG_DIR)/test_integration_tlb.log
	@if [ -f test_integration_tlb.vcd ]; then mv test_integration_tlb.vcd $(WAVE_DIR)/; fi
	@echo ""

# Run all tests
test_all: test_storage test_lookup test_lru test_ptw test_memory test_integration_memory_ptw test_integration_tlb
	@echo "========================================="
	@echo "All tests completed. Check logs directory for details."
	@echo "========================================="
	@grep -h "ALL TESTS" $(LOG_DIR)/*.log || true
	@echo "========================================="

# Unit test targets
unit_tests: test_storage test_lookup test_lru test_ptw test_memory
	@echo "=== Unit tests completed ==="

# Compilation rules
$(BUILD_DIR)/test_storage$(EXT): $(TB_STORAGE) tlb_storage.v $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_STORAGE) tlb_storage.v

$(BUILD_DIR)/test_lookup$(EXT): $(TB_LOOKUP) tlb_lookup.v $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_LOOKUP) tlb_lookup.v

$(BUILD_DIR)/test_lru$(EXT): $(TB_LRU) tlb_lru.v $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_LRU) tlb_lru.v

$(BUILD_DIR)/test_ptw$(EXT): $(TB_PTW) ptw.v $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_PTW) ptw.v

$(BUILD_DIR)/test_memory$(EXT): $(TB_MEMORY) memory.v $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_MEMORY) memory.v

$(BUILD_DIR)/test_integration_memory_ptw$(EXT): $(TB_INTEGRATION_MEMORY_PTW) $(SRC_FILES) $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_INTEGRATION_MEMORY_PTW) $(SRC_FILES)

$(BUILD_DIR)/test_integration_tlb$(EXT): $(TB_INTEGRATION_TLB) $(SRC_FILES) $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_INTEGRATION_TLB) $(SRC_FILES)

# View waveforms (for iverilog with gtkwave)
wave: $(WAVE_DIR)/test_integration_tlb.vcd
	gtkwave $(WAVE_DIR)/test_integration_tlb.vcd &

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
	@echo "  test_ptw       - Run PTW module test"
	@echo "  test_memory    - Run MEMORY module test"
	@echo "  test_integration_memory_ptw - Run integration test"
	@echo "  test_integration_tlb - Run integration test"
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

.PHONY: all test_all unit_tests test_storage test_lookup test_lru test_ptw test_memory test_integration_memory_ptw test_integration wave coverage clean help