`timescale 1ns/10ps

module minisrc(
    input  wire Clock,
    input  wire Reset,
    input  wire Stop,
    input  wire [31:0] in_port_sim,  // External input port simulation
    output wire [31:0] IR_out,       // Instruction Register output (for observation)
    output wire Run,               // Run indicator (1 when processor running)
    output wire Halt,              // Halt indicator (set when HALT instruction executed)
    output wire [31:0] BusData     // Bus output (for observation)
);

    // --- Declare wires connecting Control Unit and Datapath ---
    // Control unit outputs:
    wire e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_CON_FF, e_OutPort, e_InPort;
    wire incPC;
    wire e_MDR, e_MAR;
    wire ram_read, ram_write, MDR_read;
    wire [3:0] ALU_op;
    wire [4:0] BusDataSelect;
    wire Gra, Grb, Grc, e_Rin, e_Rout, BAout;
    wire imm_sel;
    wire Clear;
    
    // If you have additional enable signals (like for RA or CON FF), tie them to 1 or route them appropriately.
    wire e_RA = 1'b1;
    
    // --- Instantiate the Control Unit ---
    control_unit CU (
        .Gra(Gra), .Grb(Grb), .Grc(Grc),
        .e_Rin(e_Rin), .e_Rout(e_Rout), .BAout(BAout),
        .e_MDR(e_MDR), .e_MAR(e_MAR), .MDR_read(MDR_read),
        .ram_read(ram_read), .ram_write(ram_write),
        .e_PC(e_PC), .e_IR(e_IR), .e_Y(e_Y), .e_Z(e_Z),
        .e_HI(e_HI), .e_LO(e_LO), .e_CON_FF(e_CON_FF),
        .e_OutPort(e_OutPort), .e_InPort(e_InPort),
        .incPC(incPC),
        .ALU_op(ALU_op),
        .BusDataSelect(BusDataSelect),
        .imm_sel(imm_sel),
        .Clear(Clear), .Run(Run),
        .IR(IR_out),  // Control unit monitors IR
        .Clock(Clock), .Reset(Reset), .Stop(Stop), .CON_out(1'b0) // Tie CON_out to 0 for now
    );
    
    // --- Instantiate the Datapath ---
    datapath DP (
        .clear(Clear),
        .clock(Clock),
        .incPC(incPC),
        .e_PC(e_PC), .e_IR(e_IR), .e_Y(e_Y), .e_Z(e_Z),
        .e_HI(e_HI), .e_LO(e_LO), .e_MDR(e_MDR), .e_MAR(e_MAR),
        .e_OutPort(e_OutPort), .e_InPort(e_InPort),
        .e_RA(e_RA), .e_CON_FF(e_CON_FF),
        .ram_read(ram_read), 
        .ram_write(ram_write),
        .MDR_read(MDR_read),
        .in_port_sim(in_port_sim),
        .ALU_op(ALU_op),
        .BusDataSelect(BusDataSelect),
        .Gra(Gra), .Grb(Grb), .Grc(Grc),
        .e_Rin(e_Rin), .e_Rout(e_Rout), .BAout(BAout),
        .imm_sel(imm_sel),
        .IRout(IR_out),
        .BusData(BusData)
    );
    

endmodule
