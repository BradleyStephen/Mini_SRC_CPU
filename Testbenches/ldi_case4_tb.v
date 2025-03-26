`timescale 1ns/10ps
module ldi_case4_tb;

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
  // Instruction 0: ldi R2, 0x78 (fetched at PC = 0)
  // Instruction 1: ld R6, 0x63(R2) (fetched at PC = 1)
  reg [4:0] state;
  localparam 
      // --- ldi R2, 0x78 sequence ---
      LDI_T0      = 5'd0,   // T0: Fetch instruction from address 0
      LDI_T0_WAIT = 5'd1,
      LDI_T1      = 5'd2,   // T1: Read memory at MAR (fetch ldi instruction)
      LDI_T1_WAIT = 5'd3,
      LDI_T2      = 5'd4,   // T2: Transfer MDR -> IR
      LDI_T3      = 5'd5,   // T3: Output R0 onto Y (to get 0)
      LDI_T4      = 5'd6,   // T4: ALU computes 0 + immediate (0x78) → Z
      LDI_T5      = 5'd7,   // T5: Write Z to R2 (Gra selects R2, IR[26..23] = 0010)
      LDI_DONE    = 5'd8,
      
      // --- ld R6, 0x63(R2) sequence ---
      LD_T0       = 5'd9,   // T0: Fetch instruction from address 1
      LD_T0_WAIT  = 5'd10,
      LD_T1       = 5'd11,  // T1: Read memory at MAR (fetch ld instruction)
      LD_T1_WAIT  = 5'd12,
      LD_T2       = 5'd13,  // T2: Transfer MDR -> IR
      LD_T3       = 5'd14,  // T3: Output R2 onto Y (R2 is the base register)
      LD_T4       = 5'd15,  // T4: ALU computes R2 + immediate (0x63) → Z
      LD_T5       = 5'd16,  // T5: Write Z to MAR (effective address = 0x78+0x63 = 0xDB)
      LD_T5_WAIT  = 5'd17,
      
      DONE        = 5'd18;
      
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
    clear       = 1;     // Start in reset.
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
    state = LDI_T0;
    
    // Deassert reset after 50 ns.
    #50 clear = 0;
  end
  
//-------------------------------------------------
  // Combined FSM: First, execute ldi R2, 0x78; then execute ld R6, 0x63(R2)
  //-------------------------------------------------
  always @(posedge clock) begin
    case(state)
      // ---------------------------
      // ldi R2, 0x78 sequence (instruction word at address 0 should be 0x42000078)
      // ---------------------------
      LDI_T0: begin
         incPC <= 1;
         e_MAR <= 1;
         BusDataSelect <= 5'b10100; // PCout
         state <= LDI_T0_WAIT;
      end
      LDI_T0_WAIT: begin
         incPC <= 0;
         e_MAR <= 0;
         BusDataSelect <= 5'b00000;
         state <= LDI_T1;
      end
      LDI_T1: begin
         // Read memory at MAR (fetch ldi instruction).
         ram_read <= 1;
         // **Do not drive a leftover source here** – use no-op.
         BusDataSelect <= 5'b00000;
         state <= LDI_T1_WAIT;
      end
      LDI_T1_WAIT: begin
         ram_read <= 0;
         MDR_read <= 1;
         e_MDR <= 1;
         BusDataSelect <= 5'b00000;
         state <= LDI_T2;
      end
      LDI_T2: begin
         // Transfer instruction from MDR -> IR.
         MDR_read <= 0;
         e_MDR <= 0;
         e_IR <= 1;
         BusDataSelect <= 5'b10101; // MDRout
         state <= LDI_T3;
      end
      LDI_T3: begin
         e_IR <= 0;
         // Output R0 (0) to Y.
         Grb <= 1;
         BAout <= 1;
         e_Y <= 1;
         BusDataSelect <= 5'b00000; // R0out
         state <= LDI_T4;
      end
      LDI_T4: begin
         Grb <= 0; BAout <= 0; e_Y <= 0;
         // ALU computes 0 + immediate (0x78).
         imm_sel <= 1;
         ALU_op <= 4'b0011; // ADD
         e_Z <= 1;
         BusDataSelect <= 5'b00000;
         state <= LDI_T5;
      end
      LDI_T5: begin
         e_Z <= 0; imm_sel <= 0;
         // Write Z to R2. For ldi R2, IR[26..23] should be 0010.
         Gra <= 1;
         e_Rin <= 1;
         BusDataSelect <= 5'b10011; // Zlowout
         state <= LDI_DONE;
      end
      LDI_DONE: begin
         Gra <= 0; e_Rin <= 0;
         BusDataSelect <= 5'b00000;
         // R2 now holds 0x78.
         state <= LD_T0;
      end
      // ---------------------------
      // ld R6, 0x63(R2) sequence (instruction word at address 1 should be 0x43100063)
      // ---------------------------
      LD_T0: begin
         incPC <= 1;
         e_MAR <= 0;
         BusDataSelect <= 5'b10100; // PCout
         state <= LD_T0_WAIT;
      end
      
      LD_T0_WAIT: begin
         incPC <= 0;
         e_MAR <= 1;
         BusDataSelect <= 5'b10100; // PCout
         state <= LD_T1;
      end
      
      LD_T1: begin
         // Fetch the ld instruction from RAM.
         e_MAR <= 0;
         ram_read <= 1;
         BusDataSelect <= 5'b00000; // No bus driving here
         state <= LD_T1_WAIT;
      end
      
      LD_T1_WAIT: begin
         ram_read <= 0;
         MDR_read <= 1;
         e_MDR <= 1;
         BusDataSelect <= 5'b00000;
         state <= LD_T2;
      end
      
      LD_T2: begin
         // Transfer instruction from MDR to IR.
         MDR_read <= 0;
         e_MDR <= 0;
         e_IR <= 1;
         BusDataSelect <= 5'b10101; // MDRout
         state <= LD_T3;
      end
      
      LD_T3: begin
         e_IR <= 0;
         // Output R2 onto Y so that ALU can compute R2 + immediate.
         Grb <= 1;   // Select R2 (IR[22:19] should be 0010)
         BAout <= 0;
         e_Y <= 1;
         BusDataSelect <= 5'b00010; // Code for R2out (verify with your bus module)
         state <= LD_T4;
      end
      
      LD_T4: begin
         Grb <= 0; e_Y <= 0;
         // ALU computes R2 + immediate (0x63).
         imm_sel <= 1;
         ALU_op <= 4'b0011; // ADD
         e_Z <= 1;
         BusDataSelect <= 5'b00000;
         state <= LD_T5;
      end
      
     LD_T5: begin
         e_Z <= 0; 
         imm_sel <= 0;
         // Directly write the ALU result (0xDB) from Zlow to R6.
         Gra <= 1;       // IR field should select R6 (e.g. 0110)
         e_Rin <= 1;
         BusDataSelect <= 5'b10011; // Zlowout: effective address on the bus.
         state <= LD_T5_WAIT;
      end
      
      LD_T5_WAIT: begin
         Gra <= 0;
         e_Rin <= 0;
         BusDataSelect <= 5'b00000;
         state <= DONE;  // End of sequence.
      end
      DONE: begin
         $finish;
      end
      default: state <= DONE;
    endcase
  end

endmodule
