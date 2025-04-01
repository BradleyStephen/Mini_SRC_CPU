`timescale 1ns/10ps

module minisrc(
    input  wire Clock,
    input  wire Reset,
    input  wire Stop,
    input  wire [31:0] in_port_sim,  // External input port simulation
    output wire [31:0] IR_out,       // Instruction Register output (for observation)
    output wire [31:0] PC_out,       // PC output (for observation)
    output wire Run,               // Run indicator (1 when processor running)
    output wire Halt,              // Halt indicator (set when HALT instruction executed)
    output wire [31:0] BusData     // Bus output (for observation)
);

    // --- Declare wires connecting Control Unit and Datapath ---
    // Control unit outputs:
    wire PCin, IRin, Yin, Zin, HIin, LOin, CONin, OutPortIn, InPortOut;
    wire IncPC, PCout_ctrl;
    wire MDRin, MARin;
    wire ram_read, ram_write, MDR_read;
    wire [3:0] ALU_op;
    wire [4:0] BusDataSelect;
    wire Gra, Grb, Grc, Rin_ctrl, Rout_ctrl, BAout;
    wire imm_sel;
    wire Clear;
    
    // Tie internal datapath enable signals to control unit outputs.
    // (Your datapath expects e_PC, e_IR, e_Y, etc. Here we use the same names.)
    wire e_PC = PCin;
    wire e_IR = IRin;
    wire e_Y  = Yin;
    wire e_Z  = Zin;
    wire e_HI = HIin;
    wire e_LO = LOin;
    wire e_MDR = MDRin;
    wire e_MAR = MARin;
    // General purpose enable is not driven by control so tie to 1:
    wire e_GP = 1'b1;
    wire e_OutPort = OutPortIn;
    wire e_InPort = InPortOut;
    // If you have additional enable signals (like for RA or CON FF), tie them to 1 or route them appropriately.
    wire e_RA = 1'b1;
    wire e_CON_FF = 1'b1;
    
    // --- Instantiate the Control Unit ---
    control_unit CU (
        .Gra(Gra), .Grb(Grb), .Grc(Grc),
        .Rin(Rin_ctrl), .Rout(Rout_ctrl), .BAout(BAout),
        .MDRin(MDRin), .MARin(MARin), .MDR_read(MDR_read),
        .ram_read(ram_read), .ram_write(ram_write),
        .PCin(PCin), .IRin(IRin), .Yin(Yin), .Zin(Zin),
        .HIin(HIin), .LOin(LOin), .CONin(CONin),
        .OutPortIn(OutPortIn), .InPortOut(InPortOut),
        .IncPC(IncPC), .PCout(PCout_ctrl),
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
        .incPC(IncPC),
        .e_PC(e_PC), .e_IR(e_IR), .e_Y(e_Y), .e_Z(e_Z),
        .e_HI(e_HI), .e_LO(e_LO), .e_MDR(e_MDR), .e_MAR(e_MAR),
        .e_GP(e_GP), .e_OutPort(e_OutPort), .e_InPort(e_InPort),
        .e_RA(e_RA), .e_CON_FF(e_CON_FF),
        .ram_read(ram_read), 
        .ram_write(ram_write),
        .MDR_read(MDR_read),
        .in_port_sim(in_port_sim),
        .ALU_op(ALU_op),
        .BusDataSelect(BusDataSelect),
        .Gra(Gra), .Grb(Grb), .Grc(Grc),
        .e_Rin(Rin_ctrl), .e_Rout(Rout_ctrl), .BAout(BAout),
        .imm_sel(imm_sel),
        .IRout(IR_out),
        .BusData(BusData),
        .BusIn_PC(PC_out)
    );
    

endmodule
