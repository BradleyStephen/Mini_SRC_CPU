`timescale 1ns/10ps
module minisrc (
    input Clock,
    input Reset,
    input Stop,
    input Con_FF,              // Optional external condition flag input if needed
    input [31:0] in_port_sim    // External input data
);
    // Wire declarations for the signals connecting control unit and datapath:
    wire e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MDR, e_MAR, e_GP, e_OutPort, e_InPort;
    wire e_RA, e_CON_FF;
    wire ram_read, ram_write, MDR_read;
    wire [3:0] ALU_op;
    wire [4:0] BusDataSelect;
    wire imm_sel;
    wire Gra, Grb, Grc;
    
    // The Instruction Register output from the datapath that goes to the control unit:
    wire [31:0] IR;
    
    // Connect the datapath. (Your datapath file remains unchanged.)
    datapath dp (
        .clear(Reset),
        .clock(Clock),
        .incPC(1'b0),         // if you use a separate incPC signal, wire it here (or generate it in control unit)
        .e_PC(e_PC),
        .e_IR(e_IR),
        .e_Y(e_Y),
        .e_Z(e_Z),
        .e_HI(e_HI),
        .e_LO(e_LO),
        .e_MDR(e_MDR),
        .e_MAR(e_MAR),
        .e_GP(e_GP),
        .e_OutPort(e_OutPort),
        .e_InPort(e_InPort),
        .e_RA(e_RA),
        .e_CON_FF(e_CON_FF),
        .ram_read(ram_read),
        .ram_write(ram_write),
        .Mdatain(),           // Connect to memory output if needed
        .MDR_read(MDR_read),
        .ALU_op(ALU_op),
        .BusDataSelect(BusDataSelect),
        .Gra(Gra),
        .Grb(Grb),
        .Grc(Grc),
        .e_Rin(),             // Your datapath’s select/encode inputs may be driven by control unit signals
        .e_Rout(),            // You may need to adapt these connections.
        .BAout(),             // Similarly, adapt as needed.
        .imm_sel(imm_sel),
        .in_port_sim(in_port_sim)
    );
    
    // Connect the control unit.
    control_unit cu (
        .e_PC(e_PC),
        .e_IR(e_IR),
        .e_Y(e_Y),
        .e_Z(e_Z),
        .e_HI(e_HI),
        .e_LO(e_LO),
        .e_MDR(e_MDR),
        .e_MAR(e_MAR),
        .e_GP(e_GP),
        .e_OutPort(e_OutPort),
        .e_InPort(e_InPort),
        .e_RA(e_RA),
        .e_CON_FF(e_CON_FF),
        .ram_read(ram_read),
        .ram_write(ram_write),
        .MDR_read(MDR_read),
        .ALU_op(ALU_op),
        .BusDataSelect(BusDataSelect),
        .imm_sel(imm_sel),
        .Gra(Gra),
        .Grb(Grb),
        .Grc(Grc),
        .IR(IR),             // Connect IR from datapath to control unit for instruction decoding.
        .Clock(Clock),
        .Reset(Reset),
        .Stop(Stop),
        .Con_FF(Con_FF)
    );
    
    // (Optionally, add connections to memory if needed, and expose registers for observation.)
    
endmodule
