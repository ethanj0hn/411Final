transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl/rv32i_mux_types.sv}
vlog -sv -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl/register.sv}
vlog -sv -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl/regfile.sv}
vlog -sv -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl/pc_reg.sv}
vlog -sv -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl/rv32i_types.sv}
vlog -sv -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl/mux.sv}
vlog -sv -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl/ir.sv}
vlog -sv -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl/control.sv}
vlog -sv -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl/cmp.sv}
vlog -sv -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl/alu.sv}
vlog -sv -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl/datapath.sv}
vlog -sv -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hdl/mp2.sv}

vlog -sv -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hvl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hvl/memory.sv}
vlog -sv -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hvl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hvl/random_tb.sv}
vlog -vlog01compat -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hvl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hvl/rvfimon.v}
vlog -sv -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hvl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hvl/source_tb.sv}
vlog -sv -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hvl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hvl/tb_itf.sv}
vlog -sv -work work +incdir+C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hvl {C:/Users/akash/Documents/College_Classes/ECE_411/kashyap5/mp2/hvl/top.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L arriaii_hssi_ver -L arriaii_pcie_hip_ver -L arriaii_ver -L rtl_work -L work -voptargs="+acc"  mp2_tb

add wave *
view structure
view signals
run -all
