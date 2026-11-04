RTL_DIR = ./rtl
TB_DIR = ./testbench
BUILD_DIR = ./build
INC_DIR = +incdir+$(RTL_DIR)
SIMV = ./build/simv
COMP_OPT = -full64 -sverilog $(INC_DIR)\
		   -debug_access+all -kdb -lca \
			-timescale=1ns/100ps \
			-ntb_opts uvm-1.2 \
			-cm line+cond+fsm+tgl+branch+assert \
			-o $(BUILD_DIR)/simv
SIMV_OPT =  -cm line+cond+fsm+tgl+branch+assert \
			-cm_dir coverage.vdb \
			-cm_name siml
all: vcs simv verdi

generagte_f:
	find . -name "*.v" -o -name "*.sv" > files.f

vcs: generagte_f
	mkdir -p $(BUILD_DIR)
	vcs $(COMP_OPT) $(SIMV_OPT) -f files.f

simv: 
	$(SIMV) $(SIMV_OPT)
#verdi:
#	verdi -dbdir $(BUILD_DIR)/simv.daidir -ssf $(BUILD_DIR)/wave.fsdb &
clean:
	rm -rf $(BUILD_DIR) csrc novas* ucli.key verdiLog files.f inter.fsdb .inter.fsdb.tbsim sys*

.PHONY: all generagte_f vcs simv verdi clean