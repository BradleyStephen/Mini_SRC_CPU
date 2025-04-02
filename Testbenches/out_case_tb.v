`timescale 1ns/10ps
module out_case_tb;

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
  
  // Select and encode signals
  reg Gra, Grb, Grc, e_Rin, e_Rout, BAout;
  
  // ALU immediate select
  reg imm_sel;
  
  // FSM states
  reg [3:0] state;
  localparam 
      // Preload sequence for ldi R6, 0x0A:
      PRE_T0      = 4'd0,   // T0: Fetch instruction from PC = 0
      PRE_T0_WAIT = 4'd1,
      PRE_T1      = 4'd2,   // T1: Read memory (fetch ldi instruction)
      PRE_T1_WAIT = 4'd3,
      PRE_T2      = 4'd4,   // T2: Transfer MDR -> IR
      PRE_T3      = 4'd5,   // T3: Output R0 (0) to Y
      PRE_T4      = 4'd6,   // T4: ALU computes 0 + immediate (0x0A) → Z
      PRE_T5      = 4'd7,   // T5: Write Z to R6 (destination: R6; IR[26..23] = 0110)
      PRE_DONE    = 4'd8,
      
      // out R6 sequence:
      OUT_T0      = 4'd9,   // T0: Fetch instruction from PC = 1
      OUT_T0_WAIT = 4'd10,
      OUT_T1      = 4'd11,  // T1: Read memory (fetch out instruction)
      OUT_T1_WAIT = 4'd12,
      OUT_T2      = 4'd13,  // T2: Transfer MDR -> IR
      OUT_T3      = 4'd14,  // T3: Execute "out" control sequence: Gra, e_Rout, e_OutPort
      OUT_T4      = 4'd15,
      DONE        = 4'd16;

  // Instantiate datapath
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
    repeat (200) #10 clock = ~clock;
  end
  
  // Initial reset and signal initialization.
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
    Gra = 0; Grb = 0; Grc = 0; e_Rin = 0; e_Rout = 0; BAout = 0;
    imm_sel = 0;
    state = PRE_T0;
    #50 clear = 0;
  end
  
  // Main FSM:
  always @(posedge clock) begin
    case(state)
      // --------------------------------------------------
      // Instruction 1: ldi R6, 0x0A (at address 0, instruction word = 0x4300000A)
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
         BusDataSelect <= 5'b10011; // zlow opcode
         state <= PRE_DONE;
      end
      PRE_DONE: begin
         Gra <= 0; e_Rin <= 0;
         BusDataSelect <= 5'b00000;
         // Now R6 holds 0x0A.
         state <= OUT_T0;
      end
      
      // --------------------------------------------------
      // Instruction 2: out R6 (at address 1, instruction word = 0x46000000)
      // --------------------------------------------------
      OUT_T0: begin
          // Fetch instruction from PC = 1.
          incPC <= 1;
          e_MAR <= 1;
          BusDataSelect <= 5'b10100; // PCout
          state <= OUT_T0_WAIT;
      end
      OUT_T0_WAIT: begin
         incPC <= 0;
         e_MAR <= 0;
         BusDataSelect <= 5'b00000;
         state <= OUT_T1;
      end
      OUT_T1: begin
         // Read memory at MAR (fetch out instruction).
         ram_read <= 1;
         BusDataSelect <= 5'b00000; // no-op
         state <= OUT_T1_WAIT;
      end
      OUT_T1_WAIT: begin
         ram_read <= 0;
         MDR_read <= 1;
         e_MDR <= 1;
         state <= OUT_T2;
      end
      OUT_T2: begin
         // Transfer fetched instruction from MDR to IR.
         MDR_read <= 0;
         e_MDR <= 0;
         e_IR <= 1;
         BusDataSelect <= 5'b10101; // MDRout
         state <= OUT_T3;
      end
      OUT_T3: begin
         e_IR <= 0;
         // Now perform the "out" micro-operation.
         // Force the bus to drive the contents of R6.
         // According to your bus module, BusDataSelect = 5'b00110 selects R6.
         BusDataSelect <= 5'b00110;
         // Also, assert the control signals for output:
         Gra <= 1;       // Decode IR[26..23]: should be 0110 (R6)
         e_Rout <= 1;    // Enable R6's output onto the bus.
         e_OutPort <= 1; // Enable output port register to capture the bus data.
         state <= OUT_T4;
      end
      OUT_T4: begin
         // Extra cycle: on the next rising clock edge,
         // the out port register (synchronously) will latch the value from the bus.
         // Now deassert the out operation signals.
         Gra <= 0;
         e_Rout <= 0;
         e_OutPort <= 0;
         BusDataSelect <= 5'b00000;
         state <= DONE;
      end
      DONE: begin
         #20; // Allow a little extra time to observe the latched output.
         $finish;
      end
      
      default: state <= DONE;
    endcase
  end

endmodule
