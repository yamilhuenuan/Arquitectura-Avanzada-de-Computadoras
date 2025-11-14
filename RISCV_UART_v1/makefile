# ============================================================
# Makefile para simular proyecto RISC-V con Icarus Verilog
# Autor: Cusa Tadeo
# ============================================================

IVERILOG = iverilog
VVP      = vvp
GTKWAVE  = gtkwave


IVERILOG_FLAGS = -g2012

DESIGN_SRCS = \
  main_decoder.sv \
  Instruction_parser.sv \
  reg_file.sv \
  immediate_gen.sv \
  pc_control.sv \
  alu_decoder.sv \
  program_counter.sv \
  PCplus4.sv \
  Instruction_Memory.sv \
  MuxPC.sv \
  branch_unit.sv \
  mux_selA.sv \
  mux_selB.sv \
  ALU.sv \
  Decode_Module.sv \
  Fetch_Module.sv \
  Execute_Module.sv \
  TopLevel_CPU.sv \
  Data_Memory.sv \
  mux_writeback.sv \
  mem_manager.sv \
  gpio_leds.sv \
  gpio_switches.sv \
  uart_tx.sv \
  uart_rx.sv \
  uart_mmio.sv \
  uart_echo_top.sv \
  uart_baud_gen.sv \
  fifo_sync.sv \

TB ?= TB_TopLevel_CPU_LW_SW
TB_FILE = $(TB).sv

OUT = simu


all: run

compile:
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(OUT) $(TB_FILE) $(DESIGN_SRCS)

run: compile
	$(VVP) $(OUT)

wave: compile
	$(VVP) $(OUT)
	$(GTKWAVE) dump.vcd &

clean:
	rm -f $(OUT) dump.vcd
