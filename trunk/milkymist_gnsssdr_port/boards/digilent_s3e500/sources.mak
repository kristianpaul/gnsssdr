BOARD_SRC=$(wildcard $(BOARD_DIR)/*.v) $(BOARD_DIR)/../ise123/MM/setup.v $(BOARD_DIR)/../../gen_capabilities.v

CONBUS_SRC=$(wildcard $(CORES_DIR)/conbus/rtl/*.v)
LM32_SRC=							\
	$(CORES_GK2_DIR)/lm32/rtl/lm32_cpu_s3.v			\
	$(CORES_GK2_DIR)/lm32/rtl/lm32_instruction_unit.v	\
	$(CORES_GK2_DIR)/lm32/rtl/lm32_decoder.v		\
	$(CORES_GK2_DIR)/lm32/rtl/lm32_load_store_unit.v	\
	$(CORES_GK2_DIR)/lm32/rtl/lm32_adder.v			\
	$(CORES_GK2_DIR)/lm32/rtl/lm32_addsub.v			\
	$(CORES_GK2_DIR)/lm32/rtl/lm32_logic_op.v		\
	$(CORES_GK2_DIR)/lm32/rtl/lm32_shifter.v		\
	$(CORES_GK2_DIR)/lm32/rtl/lm32_multiplier.v		\
	$(CORES_GK2_DIR)/lm32/rtl/lm32_mc_arithmetic.v		\
	$(CORES_GK2_DIR)/lm32/rtl/lm32_interrupt.v		\
	$(CORES_DIR)/lm32/rtl/lm32_debug.v			\
	$(CORES_GK2_DIR)/lm32/rtl/ram32x32d.v			\
	$(CORES_GK2_DIR)/lm32/rtl/lm32_top.v
FMLARB_SRC=$(wildcard $(CORES_GK2_DIR)/fmlarb/*.v)
FMLBRG_SRC=$(wildcard $(CORES_GK2_DIR)/fmlbrg_32/rtl/*.v)
CSRBRG_SRC=$(wildcard $(CORES_DIR)/csrbrg/rtl/*.v)
NORFLASH_SRC=$(wildcard $(CORES_GK2_DIR)/norflash16/rtl/*.v)
UART_SRC=$(wildcard $(CORES_DIR)/uart/rtl/*.v)
SYSCTL_SRC=$(wildcard $(CORES_GNSSSDR_DIR)/sysctl/rtl/*.v)
HPDMC_SRC=$(wildcard $(CORES_GK2_DIR)/hpdmc_ddr16/rtl/*.v) $(wildcard $(CORES_GK2_DIR)/hpdmc_ddr16/rtl/SPARTAN3E/*.v)
ETHERNET_SRC=$(wildcard $(CORES_DIR)/minimac2/rtl/*.v)
FMLMETER_SRC=$(wildcard $(CORES_DIR)/fmlmeter/rtl/*.v)
MONITOR_SRC=$(wildcard $(CORES_GNSSSDR_DIR)/monitor/rtl/*.v)
NAMURU_SRC=$(wildcard $(CORES_GNSSSDR_DIR)/namuru/rtl/*.v)
WBABRG_SRC=$(wildcard $(CORES_OTHERS_DIR)/wbabrg/rtl/*.v)

CORES_SRC=$(CONBUS_SRC) $(LM32_SRC) $(FMLARB_SRC) $(FMLBRG_SRC) $(CSRBRG_SRC) $(NORFLASH_SRC) $(UART_SRC) $(SYSCTL_SRC) $(HPDMC_SRC) $(ETHERNET_SRC) $(FMLMETER_SRC) $(MONITOR_SRC) $(NAMURU_SRC) $(WBABRG_SRC)

TOP_SRC=$(BOARD_DIR)/../ise123/MM/system.v $(BOARD_DIR)/../ise123/MM/ddram.v
