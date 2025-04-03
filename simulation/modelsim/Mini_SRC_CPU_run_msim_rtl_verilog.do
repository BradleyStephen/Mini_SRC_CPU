transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/minisrc_tb.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/minisrc.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/control_unit.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/mux2to1_32.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/con_ff_logic.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU/ALU {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/ALU/subtractor_32bit.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU/ALU {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/ALU/full_adder.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU/ALU {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/ALU/divider.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU/ALU {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/ALU/booth_multiplier.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU/Registers {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/Registers/program_counter.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/bus.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU/Registers {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/Registers/register_64.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU/Registers {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/Registers/register_32.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU/Registers {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/Registers/register_file.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/datapath.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU/Registers {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/Registers/mdr.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU/ALU {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/ALU/alu.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU/ALU {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/ALU/adder_32bit.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/select_encode.v}
vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/ram.v}

vlog -vlog01compat -work work +incdir+C:/Users/18eiaj/Desktop/Mini_SRC_CPU {C:/Users/18eiaj/Desktop/Mini_SRC_CPU/minisrc_tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  minisrc_tb

add wave *
view structure
view signals
run 1000 ns
