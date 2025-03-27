`timescale 1ns/10ps
module jal_tb;

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
      
      // Instruction Fetch Sequence (T0–T2)
      JAL_FETCH_T0      = 5'd9,
      JAL_FETCH_T0_WAIT = 5'd10,
      JAL_FETCH_T1      = 5'd11,
      JAL_FETCH_T1_WAIT = 5'd12,
      JAL_FETCH_T2      = 5'd13,
      
      // JAL Sequence
      JAL_SAVE          = 5'd14,  // Save current PC (return address) into link register (R8)
      JAL_JUMP          = 5'd15,  // Output jump target from R5 onto the bus
      JAL_LOAD          = 5'd16,  // Load PC with jump target from R5
      DONE              = 5'd17;
    
      
  // Instantiate the datapath
  datapath DUT (
    .clear(clear),
    .clock(clock),
    .e_PC(e_PC),
    .incPC(incPC),
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
  always @(posedge clock) begin
    case(state)
    // ---------------------------
          // ldi R8, 0x95 sequence (instruction word at address 0 should be 0x42000078)
          // ---------------------------
          LDI_T0: begin
             e_MAR <= 1;
             BusDataSelect <= 5'b10100; // PCout
             state <= LDI_T0_WAIT;
          end
          LDI_T0_WAIT: begin
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
             // Output R0 (0) to Y.
             Grb <= 1;
             BAout <= 1;
             e_Y <= 1;
             BusDataSelect <= 5'b00000; // R0out
             state <= LDI_T4;
          end
          LDI_T4: begin
             Grb <= 0; BAout <= 0; e_Y <= 0;
             // ALU computes 0 + immediate (0x05).
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
             BusDataSelect <= 5'b01000;
             // R2 now holds 0x05.
             state <= JAL_FETCH_T0;
          end
          
      
      
          // ----------------------------
      // Instruction Fetch Sequence for jal (T0–T2).
      // ----------------------------
      JAL_FETCH_T0: begin
         e_MAR <= 1;
         BusDataSelect <= 5'b10100; // PCout drives MAR.
         state <= JAL_FETCH_T0_WAIT;
      end
      JAL_FETCH_T0_WAIT: begin
         e_MAR <= 0;
         BusDataSelect <= 5'b00000;
         state <= JAL_FETCH_T1;
      end
      JAL_FETCH_T1: begin
         ram_read <= 1;           // Initiate memory read (fetch jal instruction).
         BusDataSelect <= 5'b00000;
         state <= JAL_FETCH_T1_WAIT;
      end
      JAL_FETCH_T1_WAIT: begin
         ram_read <= 0;
         MDR_read <= 1;           // Latch data from memory.
         e_MDR <= 1;
         BusDataSelect <= 5'b00000;
         state <= JAL_FETCH_T2;
      end
      JAL_FETCH_T2: begin
         MDR_read <= 0;
         e_MDR <= 0;
              // Transfer instruction from MDR to IR.
         BusDataSelect <= 5'b10101; // MDRout drives IR.
         state <= JAL_SAVE;
      end
      
      // ----------------------------
      // JAL Execution Sequence.
      // T3 (JAL_SAVE): Save the current PC value (return address) into link register R8.
      // ----------------------------
      JAL_SAVE: begin
         BusDataSelect <= 5'b10100; // Output PC onto the bus.
         // Assume that the IR field (or a dedicated control) selects R8.
         Gra <= 1;    // Decode so that R8 is selected.
         e_Rin <= 1;  // Enable R8 input (link register write).
         state <= JAL_JUMP;
      end
      
      // T4 (JAL_JUMP): Output the jump target from R5 onto the bus.
      JAL_JUMP: begin
         // Deassert the previous saving signals.
         Gra <= 0;
         e_Rin <= 0;
         // Now, select R5 as the source for the jump target.
         Gra <= 1;   // Decode IR field to select R5.
         e_Rout <= 1; // Enable output from R5.
         BusDataSelect <= 5'b00101; // Assumed bus mapping for R5out.
         state <= JAL_LOAD;
      end
      
      // T5 (JAL_LOAD): Load PC with the jump target from R5.
      JAL_LOAD: begin
         Gra <= 0;
         e_Rout <= 0;
         e_PC <= 1;   // Load PC with the bus value.
         state <= DONE;
      end
      
      DONE: begin
         e_PC <= 0;
         BusDataSelect <= 5'b00000;
         // End of the jal instruction sequence.
      end
      
      default: state <= DONE;
    endcase
  end

endmodule
