# Makefile for TLB testbenches

# Source files
PARAM_FILE = tlb_params.vh
SRC_FILES = tlb_storage.v tlb_lookup.v tlb_lru.v tlb_controller.v tlb.v ptw.v memory.v

# Testbench files
TB_TLB_STORAGE = test_tlb_storage.v
TB_TLB_LOOKUP = test_tlb_lookup.v
TB_TLB_LRU = test_tlb_lru.v
TB_PTW = test_ptw.v
TB_MEMORY = test_memory.v
TB_INTEGRATION_MEMORY_PTW = test_integration_memory_ptw.v
TB_INTEGRATION_TLB = test_integration_tlb.v
TB_INTEGRATION_TLB_PTW_MEMORY = test_integration_tlb_ptw_memory.v

# Output directories
BUILD_DIR = build
WAVE_DIR = waves
LOG_DIR = logs

# Create directories
$(shell mkdir -p $(BUILD_DIR) $(WAVE_DIR) $(LOG_DIR))

COMPILE = iverilog -g2012 -Wall -I.
RUN = vvp
EXT = .vvp

# Default target
all: test_all

# Individual unit tests
test_tlb_storage: $(BUILD_DIR)/test_tlb_storage$(EXT)
	@echo "=== Running TLB Storage Test ==="
	$(RUN) $(BUILD_DIR)/test_tlb_storage$(EXT) | tee $(LOG_DIR)/test_tlb_storage.log
	@if [ -f test_tlb_storage.vcd ]; then mv test_tlb_storage.vcd $(WAVE_DIR)/; fi
	@echo ""

test_tlb_lookup: $(BUILD_DIR)/test_tlb_lookup$(EXT)
	@echo "=== Running TLB Lookup Test ==="
	$(RUN) $(BUILD_DIR)/test_tlb_lookup$(EXT) | tee $(LOG_DIR)/test_tlb_lookup.log
	@if [ -f test_tlb_lookup.vcd ]; then mv test_tlb_lookup.vcd $(WAVE_DIR)/; fi
	@echo ""

test_tlb_lru: $(BUILD_DIR)/test_tlb_lru$(EXT)
	@echo "=== Running TLB LRU Test ==="
	$(RUN) $(BUILD_DIR)/test_tlb_lru$(EXT) | tee $(LOG_DIR)/test_tlb_lru.log
	@if [ -f test_tlb_lru.vcd ]; then mv test_tlb_lru.vcd $(WAVE_DIR)/; fi
	@echo ""

test_ptw: $(BUILD_DIR)/test_ptw$(EXT)
	@echo "=== Running PTW Test ==="
	$(RUN) $(BUILD_DIR)/test_ptw$(EXT) | tee $(LOG_DIR)/test_ptw.log
	@if [ -f test_ptw.vcd ]; then mv test_ptw.vcd $(WAVE_DIR)/; fi
	@echo ""

test_memory: $(BUILD_DIR)/test_memory$(EXT)
	@echo "=== Running MEMORY Test ==="
	$(RUN) $(BUILD_DIR)/test_memory$(EXT) | tee $(LOG_DIR)/test_memory.log
	@if [ -f test_memory.vcd ]; then mv test_memory.vcd $(WAVE_DIR)/; fi
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

test_integration_tlb_ptw_memory: $(BUILD_DIR)/test_integration_tlb_ptw_memory$(EXT)
	@echo "=== Running TLB Integration Test ==="
	$(RUN) $(BUILD_DIR)/test_integration_tlb_ptw_memory$(EXT) | tee $(LOG_DIR)/test_integration_tlb_ptw_memory.log
	@if [ -f test_integration_tlb_ptw_memory.vcd ]; then mv test_integration_tlb_ptw_memory.vcd $(WAVE_DIR)/; fi
	@echo ""

# Run all tests
test_all: test_tlb_storage test_tlb_lookup test_tlb_lru test_ptw test_memory test_integration_memory_ptw test_integration_tlb test_integration_tlb_ptw_memory
	@echo "========================================="
	@echo "All tests completed. Check logs directory for details."
	@echo "========================================="
	@grep -h "ALL TESTS" $(LOG_DIR)/*.log || true
	@echo "========================================="

# Unit test targets
unit_tests: test_tlb_storage test_tlb_lookup test_tlb_lru test_ptw test_memory
	@echo "=== Unit tests completed ==="

# Compilation rules
$(BUILD_DIR)/test_tlb_storage$(EXT): $(TB_TLB_STORAGE) tlb_storage.v $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_TLB_STORAGE) tlb_storage.v

$(BUILD_DIR)/test_tlb_lookup$(EXT): $(TB_TLB_LOOKUP) tlb_lookup.v $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_TLB_LOOKUP) tlb_lookup.v

$(BUILD_DIR)/test_tlb_lru$(EXT): $(TB_TLB_LRU) tlb_lru.v $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_TLB_LRU) tlb_lru.v

$(BUILD_DIR)/test_ptw$(EXT): $(TB_PTW) ptw.v $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_PTW) ptw.v

$(BUILD_DIR)/test_memory$(EXT): $(TB_MEMORY) memory.v $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_MEMORY) memory.v

$(BUILD_DIR)/test_integration_memory_ptw$(EXT): $(TB_INTEGRATION_MEMORY_PTW) $(SRC_FILES) $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_INTEGRATION_MEMORY_PTW) $(SRC_FILES)

$(BUILD_DIR)/test_integration_tlb$(EXT): $(TB_INTEGRATION_TLB) $(SRC_FILES) $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_INTEGRATION_TLB) $(SRC_FILES)

$(BUILD_DIR)/test_integration_tlb_ptw_memory$(EXT): $(TB_INTEGRATION_TLB_PTW_MEMORY) $(SRC_FILES) $(PARAM_FILE)
	$(COMPILE) -o $@ $(TB_INTEGRATION_TLB_PTW_MEMORY) $(SRC_FILES)

# Clean
clean:
	rm -rf $(BUILD_DIR)/* $(LOG_DIR)/* $(WAVE_DIR)/*
	rm -f *.vcd *.log

# Help
help:
	@echo "======================"
	@echo "Targets:"
	@echo "  all            	- Run all tests (default)"
	@echo "  test_all       	- Run all tests"
	@echo "  unit_tests     	- Run only unit tests"
	@echo "  test_tlb_storage   	- Run storage module test"
	@echo "  test_tlb_lookup    	- Run lookup module test"
	@echo "  test_tlb_lru       	- Run LRU module test"
	@echo "  test_ptw       	- Run PTW module test"
	@echo "  test_memory    	- Run MEMORY module test"
	@echo "  test_integration_tlb    	- Run TLB integration test"
	@echo "  test_integration_memory_ptw 	 - Run PTW MEMORY integration test"
	@echo "  test_integration_tlb_ptw_memory - Run TLB PTW MEMORY integration test"
	@echo "  clean          	- Clean all generated files"
	@echo "  help           	- Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make test_all"
	@echo "  make test_integration_tlb_ptw_memory"
	@echo "  make clean"
	@echo "======================"

.PHONY: all test_all unit_tests test_storage test_lookup test_lru test_ptw test_memory test_integration_memory_ptw test_integration_tlb test_integration_tlb_ptw_memory clean help