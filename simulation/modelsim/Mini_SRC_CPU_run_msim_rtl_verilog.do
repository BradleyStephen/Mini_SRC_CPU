transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+D:/Users/ejele/Documents/Quartus/Mini_SRC_CPU {D:/Users/ejele/Documents/Quartus/Mini_SRC_CPU/bus_tb_erik.v}
vlog -vlog01compat -work work +incdir+D:/Users/ejele/Documents/Quartus/Mini_SRC_CPU/Registers {D:/Users/ejele/Documents/Quartus/Mini_SRC_CPU/Registers/register_64.v}
vlog -vlog01compat -work work +incdir+D:/Users/ejele/Documents/Quartus/Mini_SRC_CPU/Registers {D:/Users/ejele/Documents/Quartus/Mini_SRC_CPU/Registers/register_32.v}
vlog -vlog01compat -work work +incdir+D:/Users/ejele/Documents/Quartus/Mini_SRC_CPU/Registers {D:/Users/ejele/Documents/Quartus/Mini_SRC_CPU/Registers/register_file.v}
vlog -vlog01compat -work work +incdir+D:/Users/ejele/Documents/Quartus/Mini_SRC_CPU {D:/Users/ejele/Documents/Quartus/Mini_SRC_CPU/datapath.v}
vlog -vlog01compat -work work +incdir+D:/Users/ejele/Documents/Quartus/Mini_SRC_CPU {D:/Users/ejele/Documents/Quartus/Mini_SRC_CPU/bus_erik.v}
vlog -vlog01compat -work work +incdir+D:/Users/ejele/Documents/Quartus/Mini_SRC_CPU/Registers {D:/Users/ejele/Documents/Quartus/Mini_SRC_CPU/Registers/mdr.v}

vlog -vlog01compat -work work +incdir+D:/Users/ejele/Documents/Quartus/Mini_SRC_CPU {D:/Users/ejele/Documents/Quartus/Mini_SRC_CPU/bus_tb_erik.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  bus_tb_erik

add wave *
view structure
view signals
run 50 us
