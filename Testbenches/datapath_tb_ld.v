`timescale 1ns/10ps
module datapath_tb_ld;

 // Clock and reset signals
  reg clear, clock, incPC;
  
  // Register enable signals
  reg e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MDR, e_MAR, e_GP, e_OutPort, e_InPort;
  reg e_RA, e_CON_FF;
  
  // RAM control signals
  reg ram_read, ram_write;
  
  // Memory and ALU signals
  reg [31:0] Mdatain;
  reg MDR_read;
  
  reg [3:0] ALU_op;
  
  reg [4:0] BusDataSelect;
  
  // Select and encode control signals
  reg Gra, Grb, Grc, e_Rin, e_Rout, BAout;
  
  // ALU operand multiplexer control signal
  reg imm_sel;

  //for display

  
  // Instantiate the datapath (all submodules are instantiated within)
  datapath DUT (
    .clear(clear),
    .clock(clock),
    .incPC(incPC),
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
    .Mdatain(Mdatain),
    .MDR_read(MDR_read),
    .ALU_op(ALU_op),
    .BusDataSelect(BusDataSelect),
    .Gra(Gra),
    .Grb(Grb),
    .Grc(Grc),
    .e_Rin(e_Rin),
    .e_Rout(e_Rout),
    .BAout(BAout),
    .imm_sel(imm_sel)
  );
  
  // Clock generation: 20 ns period
  initial begin
    clock = 0;
    repeat (250) begin
      #10 clock = ~clock;
    end
  end

  // Test sequence: Verify that incPC increments the PC and that the new PC value is loaded into MAR.
  initial begin
    // Initialize all control signals and data
    clear       = 1;
    incPC       = 0;
    e_PC = 0; e_IR = 0; e_Y = 0; e_Z = 0;
    e_HI = 0; e_LO = 0; e_MDR = 0; e_MAR = 0; e_GP = 0;
    e_OutPort = 0; e_InPort = 0;
    e_RA = 0; e_CON_FF = 0;
    ram_read = 0; ram_write = 0;
    MDR_read = 0;
    ALU_op = 4'b0000;
    BusDataSelect = 5'b00000;
    Gra = 0; Grb = 0; Grc = 0;
    e_Rin = 0; e_Rout = 0; BAout = 0;
    imm_sel = 0;
    Mdatain = 32'd0;
    
    // Apply reset for 30 ns then deassert
    #30;  
    clear = 0;
    
    //----T0-----
    // Drive the PC out and increment the PC; load MAR with the new PC value.
    // (Assuming initial PC is 0.)
    incPC = 1;   // Increment PC (0 → 1)
    #20 // wait one clock cycle 

    //Now drive the new PC value onto the bus
    //assert e_PC to output current value "1" onto the bus
    incPC = 0;
    e_MAR = 1;   // Enable MAR to capture the bus value
    BusDataSelect = 5'b10100; // PC output selection on the bus (adjust if needed)
    #20;       // Wait one clock cycle
    
    // Deassert the control signals.
    e_MAR = 0;
    #20; // wait

    //----T1----
    ram_read = 1; // read ram
    MDR_read = 1; // read mdr
    #20
    e_MDR = 1;
    BusDataSelect = 5'b10101; // MDR  bus opcode
  
    #20 // wait to allow MDR to capture data

    //deassert
    ram_read = 0;
    MDR_read = 0;
    e_MDR = 0;
    BusDataSelect = 5'b00000;
    #20
             
    $finish;
  end
endmodule
