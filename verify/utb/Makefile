COMPILER = iverilog

SRC = EF_TCC32_apb_PWM_tb.v ../../hdl/rtl/EF_TCC32.v ../../hdl/rtl/bus_wrappers/EF_TCC32_apb.pp.v

OUTPUT = a.out

VCD_FILE = EF_TCC32_PWM.vcd

all: compile run

compile:
	$(COMPILER) -o $(OUTPUT) $(SRC)

run:
	./$(OUTPUT)

gtkwave:
	gtkwave $(VCD_FILE)

clean:
	rm -f $(OUTPUT) *.vcd

.PHONY: all compile run gtkwave clean