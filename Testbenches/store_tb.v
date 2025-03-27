`timescale 1ns/10ps
module store_tb;

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
      // --- ldi R3, 0xB6 sequence ---
      LDI_T0      = 5'd0,   // T0: Fetch instruction from address 0
      LDI_T0_WAIT = 5'd1,
      LDI_T1      = 5'd2,   // T1: Read memory at MAR (fetch ldi instruction)
      LDI_T1_WAIT = 5'd3,
      LDI_T2      = 5'd4,   // T2: Transfer MDR -> IR
      LDI_T3      = 5'd5,   // T3: Output R0 onto Y (to get 0)
      LDI_T4      = 5'd6,   // T4: ALU computes 0 + immediate (0x78) → Z
      LDI_T5      = 5'd7,   // T5: Write Z to R2 (Gra selects R2, IR[26..23] = 0010)
      LDI_DONE    = 5'd8,
      
      // Instruction Fetch States (T0-T2)
      FETCH_T0      = 5'd9,  // T0: PCout, MARin, IncPC, Zin
      FETCH_T0_WAIT = 5'd10,
      FETCH_T1      = 5'd11,  // T1: Read memory; Zlowout drives PCin
      FETCH_T1_WAIT = 5'd12,
      FETCH_T2      = 5'd13,  // T2: MDRout -> IR
      FETCH_T2_WAIT = 5'd14,

      ST_T3      = 5'd15,  // Compute effective address: output 0 (from R0) into Y
      ST_T4      = 5'd16,  // ALU: Y + immediate (0x34) → Z
      ST_T5      = 5'd17,  // Transfer effective address from Z into MAR
      ST_T6      = 5'd18,  // Output R3 onto the bus (for data)
      ST_T7      = 5'd19,  // Initiate RAM write: store bus value into memory at address in MAR
      ST_T7_WAIT = 5'd20,  // Deassert RAM write
      
      DONE       = 5'd21;
      
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
          // ldi R1, 0x05 sequence (instruction word at address 0 should be 0x42000078)
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
             BusDataSelect <= 5'b00000;
             // R2 now holds 0x05.
             state <= FETCH_T0;
          end
           ////////////
          // Instruction Fetch for store
          ////////////
          FETCH_T0: begin
            // T0: PCout, MARin, IncPC, Zin
            incPC <= 1;
            e_MAR <= 0;
            BusDataSelect <= 5'b10100; // PCout
            state <= FETCH_T0_WAIT;
          end
          FETCH_T0_WAIT: begin
            incPC <= 0; 
            e_MAR <= 1; 
            BusDataSelect <= 5'b10100;
            state <= FETCH_T1;
          end
          FETCH_T1: begin
            // T1: Zlowout -> PCin, initiate memory read
            e_MAR <= 0;
            ram_read <= 1;
            BusDataSelect <= 5'b00000; // 
            state <= FETCH_T1_WAIT;
          end
          FETCH_T1_WAIT: begin
            // Capture the instruction from memory into MDR
            MDR_read <= 1;
            ram_read <= 0;
            e_MDR <= 1;
            BusDataSelect <= 5'b00000;
            state <= FETCH_T2;
          end
          FETCH_T2: begin
            // T2: MDRout -> IR (fetch complete)
            MDR_read <= 0;
            e_MDR <= 0;
            e_IR <= 1;
            BusDataSelect <= 5'b10101; // MDRout
            state <= FETCH_T2_WAIT;
          end
          FETCH_T2_WAIT: begin
            // T2: MDRout -> IR (fetch complete)
            e_IR <= 0;
            BusDataSelect <= 5'b00000; // MDRout
            state <= ST_T3;
          end

          // ----------------------------
    // Store Execution Sequence for "st 0x34, R3"
    // ----------------------------
    
          ST_T3: begin
            // To compute the effective address, we assume absolute addressing:
            // effective address = 0 + immediate.  
            // We force R0 onto the bus.  (Since R0 is hardwired to 0 via BAout.)
            Grb <= 1;        // Select R0 (for instance, if IR[22:19] is 0, or simply force it)
            BAout <= 1;      // Force output to be 0
            e_Y <= 1;       // Load Y with the bus value (0)
            BusDataSelect <= 5'b00000; // Code for R0 out (R0 = 0)
            state <= ST_T4;
          end
          
          ST_T4: begin
            // Deassert the Y-driving signals.
            Grb <= 0; BAout <= 0; e_Y <= 0;
            // Now compute effective address: add immediate offset (0x34) to Y (0).
            // Activate imm_sel so that the ALU takes C_sign_ext as B.
            imm_sel <= 1;
            ALU_op <= 4'b0011;  // ADD operation: 0 + 0x34 = 0x34
            e_Z <= 1;           // Load ALU result into Z
            BusDataSelect <= 5'b11000; // Code that selects the immediate (C_sign_ext)
            state <= ST_T5;
          end
          
          ST_T5: begin
            // Now effective address is in Z.
            e_Z <= 0; 
            imm_sel <= 0;
            // Transfer the computed effective address (0x34) from Z to MAR.
            e_MAR <= 1;
            BusDataSelect <= 5'b10011; // Code for Zlowout
            state <= ST_T6;
          end
          
          ST_T6: begin
            // Deassert MAR signals.
            e_MAR <= 0;
            // Now output R3 (which contains 0xB6) onto the bus.
            // We assume that IR (or prior configuration) selects R3 for the store.
            Gra <= 1;         // This decodes IR[26:23] and selects R3 if IR[26:23]==4'b0011.
            e_Rout <= 1;      // Drive R3 onto the bus.
            BusDataSelect <= 5'b00011; // Code for R3 out (binary 00011 corresponds to R3)
            state <= ST_T7;
          end
          
          ST_T7: begin
            // With R3’s value (0xB6) on the bus and MAR holding 0x34, perform the store.
            // Deassert the signals driving R3:
            Gra <= 0;
            e_Rout <= 0;
            // Assert the RAM write signal so that the bus data is stored into memory at MAR.
            ram_write <= 1;
            state <= ST_T7_WAIT;
          end
          
          ST_T7_WAIT: begin
            // Deassert the RAM write signal.
            ram_write <= 0;
            // Clear BusDataSelect if necessary.
            BusDataSelect <= 5'b00000;
            state <= DONE;
          end

          DONE: begin
            // Deassert all signals and finish simulation
            //incPC <= 0;
            BusDataSelect <= 5'b00000;
            #20;
          end
        default: state <= DONE;
      endcase
    end

endmodule
