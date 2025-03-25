`timescale 1ns/10ps
module in_case_tb;

  // Clock and reset signals
  reg clear, clock, incPC;
  
  // Register enable signals
  reg e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MDR, e_MAR, e_GP;
  reg e_OutPort, e_InPort, e_RA, e_CON_FF;
  
  // RAM control signals
  reg ram_read, ram_write;
  
  // Memory and ALU signals (Mdatain is driven by RAM)
  wire [31:0] Mdatain;
  reg MDR_read;
  
  reg [3:0] ALU_op;
  reg [4:0] BusDataSelect;
  
  // Select and encode control signals
  reg Gra, Grb, Grc, e_Rin, e_Rout, BAout;
  
  // ALU immediate select
  reg imm_sel;

  //inport data connection foor simulation
  reg [31:0] in_data;
  
  // FSM states (we use a 4-bit state encoding)
  reg [3:0] state;
  localparam 
      RESET    = 4'd0,
      T0       = 4'd1,  // T0: Fetch instruction from PC = 0
      T0_WAIT  = 4'd2,
      T1       = 4'd3,  // T1: Read memory (fetch instruction)
      T1_WAIT  = 4'd4,
      T2       = 4'd5,  // T2: Transfer MDR -> IR
      T3       = 4'd6,  // T3: Execute "in" operation: load input port value into register R3
      DONE     = 4'd7;
  
  // Instantiate the datapath (all submodules instantiated inside)
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
    .imm_sel(imm_sel),
    .in_port_sim(in_data)
  );
  
  // Clock generation: 20 ns period.
  initial begin
    clock = 0;
    repeat (200) #10 clock = ~clock;
  end
  
  // Initial reset and control signal initialization.
  initial begin
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
    state = RESET;
    
    // Release reset after 50 ns.
    #50 clear = 0;
  end
  
  // For simulation, force the input port's data to a constant value.
  // Here we force the in_port's D input (in_port_data) to 0x00000077.
  // (Assuming your datapath instance is DUT and your in_port module's input is called in_port_data.)
  initial begin
    // Adjust the hierarchical name if needed.
    in_data = 32'h00000077;
  end
  
  // Main FSM: fetch the "in R3" instruction and execute it.
  always @(posedge clock) begin
    case(state)
      RESET: begin
        state <= T0;
      end
      T0: begin
        // T0: Fetch instruction from PC = 0.
        incPC <= 1;
        e_MAR <= 1;
        BusDataSelect <= 5'b10100;  // PCout
        state <= T0_WAIT;
      end
      T0_WAIT: begin
        incPC <= 0;
        e_MAR <= 0;
        BusDataSelect <= 5'b00000;
        state <= T1;
      end
      T1: begin
        // T1: Read memory at address in MAR (fetch the "in" instruction).
        ram_read <= 1;
        BusDataSelect <= 5'b00000; // no-op (do not drive any leftover bus data)
        state <= T1_WAIT;
      end
      T1_WAIT: begin
        ram_read <= 0;
        MDR_read <= 1;
        e_MDR <= 1;
        BusDataSelect <= 5'b00000;
        state <= T2;
      end
      T2: begin
        // T2: Transfer instruction from MDR to IR.
        MDR_read <= 0;
        e_MDR <= 0;
        e_IR <= 1;
        BusDataSelect <= 5'b10101; // MDRout
        state <= T3;
      end
      T3: begin
        // T3: Execute the in operation.
        // For "in R3", IR should indicate destination register R3 (bits [26:23] = 0011).
        // To load the input port value into R3, set BusDataSelect to 5'b10110 (which selects BusMuxIn_InPort),
        // and assert Gra and e_Rin so that the register file loads the bus data.
        e_IR <= 0;
        Gra <= 1;    // Select destination from IR (should be R3)
        e_Rin <= 1;  // Enable register file write
        BusDataSelect <= 5'b10110; // Select input port output onto bus.
        state <= DONE;
      end
      DONE: begin
        // Allow one more clock edge for the register to latch the bus value.
        #20;
        $finish;
      end
      default: state <= DONE;
    endcase
  end

endmodule
