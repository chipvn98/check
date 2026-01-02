#================================================
# FILE: prj_sva_ahb/sim/Makefile
#================================================

VSIM = vsim
VLOG = vlog
VLIB = vlib

TOP = tb_top

TB = \
  ../tb/ahb_if.sv \
  ../tb/ahb_assertions.sv \
  ../tb/ahb_coverage.sv \
  ../tb/ahb_stimulus.sv \
  ../tb/tb_top.sv

all:
	$(VLIB) work
	$(VLOG) -sv -cover bcesft $(TB)
	$(VSIM) -coverage $(TOP) -do run.do

clean:
	rm -rf work transcript *.wlf *.ucdb

