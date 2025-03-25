`timescale 1ns/10ps
module andi_case_tb;

  // Clock and reset signals
  reg clear, clock, incPC;
  
  // Register enable signals
  reg e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MDR, e_MAR, e_GP, e_OutPort, e_InPort;
  reg e_RA, e_CON_FF;
  
  // RAM control signals
  reg ram_read, ram_write;
  
  // Memory and ALU signals (Mdatain is driven by RAM)
  wire [31:0] Mdatain;
  reg MDR_read;
  
  reg [3:0] ALU_op;
  reg [4:0] BusDataSelect;
  
  // Select and encode control signals
  reg Gra, Grb, Grc, e_Rin, e_Rout, BAout;
  
  // ALU operand multiplexer control signal
  reg imm_sel;
  
  // FSM states for a two-instruction sequence:
  // (1) Preload: ldi R6, 0x0A  (RAM address 0 holds 0x4300000A)
  // (2) Operation: ANDI R5, R6, -7  (RAM address 1 holds 0x42B7FFF9)
  reg [4:0] state;
  localparam 
      // Preload sequence for ldi R6, 0x0A:
      PRE_T0      = 5'd0,   // T0: Fetch instruction from PC = 0
      PRE_T0_WAIT = 5'd1,
      PRE_T1      = 5'd2,   // T1: Read memory to load ldi instruction
      PRE_T1_WAIT = 5'd3,
      PRE_T2      = 5'd4,   // T2: Transfer MDR -> IR
      PRE_T3      = 5'd5,   // T3: Output R0 onto Y (to get 0)
      PRE_T4      = 5'd6,   // T4: ALU computes 0 + immediate (0x0A) → Z
      PRE_T5      = 5'd7,   // T5: Write Z to R6 (destination: R6; IR[26..23] should be 0110)
      PRE_DONE    = 5'd8,
      
      // ANDI sequence for ANDI R5, R6, -7:
      ANDI_T0      = 5'd9,   // T0: Fetch instruction from PC = 1
      ANDI_T0_WAIT = 5'd10,
      ANDI_T1      = 5'd11,  // T1: Read memory to load ANDI instruction
      ANDI_T1_WAIT = 5'd12,
      ANDI_T2      = 5'd13,  // T2: Transfer MDR -> IR
      ANDI_T3      = 5'd14,  // T3: Output R6 onto Y (source register; IR[22:19] = 0110)
      ANDI_T4      = 5'd15,  // T4: ALU computes R6 + immediate (-7) → Z
      ANDI_T5      = 5'd16,  // T5: Write Z to R5 (destination; IR[26:23] should be 0101)
      ANDI_DONE    = 5'd17,
      DONE         = 5'd18;
      
  // Instantiate the datapath
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
  
  // Clock generation: 20 ns period.
  initial begin
    clock = 0;
    repeat (300) begin
      #10 clock = ~clock;
    end
  end
  
  // Initial reset and signal initialization.
  initial begin
    clear       = 1;  // Assert reset initially.
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
    state = PRE_T0;
    
    // Deassert reset after 50 ns.
    #50 clear = 0;
  end
  
  //-------------------------------------------------
  // FSM for ANDI R5, R6, -7 demonstration.
  //-------------------------------------------------
  always @(posedge clock) begin
    case(state)
      // --------------------------------------------------
      // Preload sequence: ldi R6, 0x0A (instruction word at address 0 = 0x4300000A)
      // --------------------------------------------------
      PRE_T0: begin
         // Fetch instruction from PC = 0.
         incPC <= 1;
         e_MAR <= 1;
         e_Z <= 1;
         BusDataSelect <= 5'b10100;  // PCout
         state <= PRE_T0_WAIT;
      end
      PRE_T0_WAIT: begin
         incPC <= 0; e_MAR <= 0; e_Z <= 0;
         BusDataSelect <= 5'b00000;
         state <= PRE_T1;
      end
      PRE_T1: begin
         // Read memory at MAR (fetch ldi instruction).
         ram_read <= 1;
         BusDataSelect <= 5'b10011; // zlow op
         state <= PRE_T1_WAIT;
      end
      PRE_T1_WAIT: begin
         MDR_read <= 1;
         ram_read <= 0;
         e_MDR <= 1;
         BusDataSelect <= 5'b00000;
         state <= PRE_T2;
      end
      PRE_T2: begin
         // Transfer instruction from MDR -> IR.
         MDR_read <= 0; //hereeee
         e_MDR <= 0;
         e_IR <= 1;
         BusDataSelect <= 5'b10101; // MDRout
         state <= PRE_T3;
      end
      PRE_T3: begin
         e_IR <= 0;
         // For ldi, output R0 (0) to Y.
         Grb <= 1;       // Select Rb (assumed to pick R0 when IR[22:19] = 0)
         BAout <= 1;     // Force zero
         e_Y <= 1;
         BusDataSelect <= 5'b00000; // R0out
         state <= PRE_T4;
      end
      PRE_T4: begin
         Grb <= 0; BAout <= 0; e_Y <= 0;
         // ALU computes 0 + immediate (0x0A)
         imm_sel <= 1;
         ALU_op <= 4'b0011; // ADD operation
         e_Z <= 1;
         BusDataSelect <= 5'b00000;
         state <= PRE_T5;
      end
      PRE_T5: begin
         e_Z <= 0; imm_sel <= 0;
         // Write Z to register file using Gra.
         // For ldi R6, IR[26..23] must be 0110 (R6)
         Gra <= 1;
         e_Rin <= 1;
         BusDataSelect <= 5'b10011; // R6out (assuming code for R6out is 00110)
         state <= PRE_DONE;
      end
      PRE_DONE: begin
         Gra <= 0; e_Rin <= 0;
         BusDataSelect <= 5'b00000;
         // Now R6 holds 0x0A.
         state <= ANDI_T0;
      end
      // --------------------------------------------------
      // ANDI sequence: ANDI R5, R6, 0x95 (instruction word at address 1 = 0x42D0095)
      // --------------------------------------------------
      ANDI_T0: begin
         // Fetch instruction from PC = 1.
         incPC <= 1;
         e_MAR <= 0;
         BusDataSelect <= 5'b00000; // chat put pc op here but didnt work
         state <= ANDI_T0_WAIT;
      end
      ANDI_T0_WAIT: begin
         incPC <= 0;
         e_MAR <= 1;
         BusDataSelect <= 5'b10100; //pc op
         state <= ANDI_T1;
      end
      ANDI_T1: begin
         // Read memory at MAR (fetch ANDI instruction).
         e_MAR <= 0;
         ram_read <= 1;
         BusDataSelect <= 5'b00000; // no-op
         state <= ANDI_T1_WAIT;
      end
      ANDI_T1_WAIT: begin
         ram_read <= 0;
         MDR_read <= 1;
         e_MDR <= 1;
         BusDataSelect <= 5'b00000;
         state <= ANDI_T2;
      end
      ANDI_T2: begin
         // Transfer instruction from MDR -> IR.
         MDR_read <= 0;
         e_MDR <= 0;
         e_IR <= 1;
         BusDataSelect <= 5'b10101; // MDRout
         state <= ANDI_T3;
      end
      ANDI_T3: begin
         e_IR <= 0;
         // For ANDI, output R6 onto Y.
         Grb <= 1;    // Select Rb; IR[22..19] should be 0110 for R6.
         BAout <= 0;
         e_Y <= 1;
         BusDataSelect <= 5'b00110; // R6out
         state <= ANDI_T4;
      end
      ANDI_T4: begin
         Grb <= 0; e_Y <= 0;
         // ALU computes R6 + immediate (0x95).
         imm_sel <= 1;
         ALU_op <= 4'b0000; // AND operation.
         e_Z <= 1;
         BusDataSelect <= 5'b00000;
         state <= ANDI_T5;
      end
      ANDI_T5: begin
         e_Z <= 0; imm_sel <= 0;
         // Write Z to register file. For ANDI R5, IR[26..23] must be 0101 (R5).
         Gra <= 1;
         e_Rin <= 1;
         BusDataSelect <= 5'b10011; // R5out (assuming code for R5out is 00101)
         state <= ANDI_DONE;
      end
      ANDI_DONE: begin
         Gra <= 0; e_Rin <= 0;
         BusDataSelect <= 5'b00000;
         state <= DONE;
      end
      DONE: begin
         $finish;
      end
      default: state <= DONE;
    endcase
  end

endmodule
