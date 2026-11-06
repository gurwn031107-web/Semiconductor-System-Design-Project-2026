set root_dir [file dirname [file normalize [info script]]]
create_project rv32i_multicycle [file join $root_dir vivado_project]
add_files [file join $root_dir rtl pkg rv32i_pkg.sv]
add_files [glob [file join $root_dir rtl *.sv]]
add_files [file join $root_dir rtl define.svh]
set_property include_dirs [list [file join $root_dir rtl]] [get_filesets sources_1]
set_property top rv32i_top [get_filesets sources_1]
add_files -fileset sim_1 [file join $root_dir tb tb_multicycle.sv]
set_property top tb_multicycle [get_filesets sim_1]
set_property xsim.elaborate.xelab.more_options {-timescale 1ns/1ps} [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
