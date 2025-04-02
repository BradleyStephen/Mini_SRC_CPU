`timescale 1ns/10ps
module ldi_case3_tb;

  // Clock and reset signals
  reg clear, clock, incPC;
  
  // Register enable signals
  reg e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MDR, e_MAR, e_GP, e_OutPort, e_InPort;
  reg e_RA, e_CON_FF;
  
  // RAM control signals
  reg ram_read, ram_write;
  
  // Memory and ALU signals (Mdatain is driven by your RAM module)
  wire [31:0] Mdatain;
  reg MDR_read;
  
  reg [3:0] ALU_op;
  
  reg [4:0] BusDataSelect;
  
  // Select and encode control signals
  reg Gra, Grb, Grc, e_Rin, e_Rout, BAout;
  
  // ALU operand multiplexer control signal
  reg imm_sel;
  
  // We define states for two instructions:
  //  1. ldi R2, 0x78
 
  // Each instruction uses T0–T2 for fetch, then T3+ for execution.
  reg [4:0] state;
  localparam 
      // --- ldi R2, 0x78 sequence ---
      LDI_T0      = 5'd0,  // T0: PCout, MARin, IncPC, Zin
      LDI_T0_WAIT = 5'd1,
      LDI_T1      = 5'd2,  // T1: read memory -> MDR
      LDI_T1_WAIT = 5'd3,
      LDI_T2      = 5'd4,  // T2: MDRout -> IR
      LDI_T3      = 5'd5,  // T3: we want 0 in Y, so we output R0 if needed
      LDI_T4      = 5'd6,  // T4: ALU does (0 + 0x78) => Z
      LDI_T5      = 5'd7,  // T5: Zlowout -> R2
      LDI_DONE    = 5'd8,
      DONE        = 5'd9;

     

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
  
  // Clock generation: 20 ns period
  initial begin
    clock = 0;
    repeat (300) begin
      #10 clock = ~clock;
    end
  end
  
  // Initial reset and control signal initialization
  initial begin
    clear       = 1;     // Start in reset
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
    state = LDI_T0;
    
    // Deassert reset after 50 ns
    #50 clear = 0;
  end
  
  //-------------------------------------------------
  // Combined FSM: first do "ldi R2, 0x78", then "ld R6, 0x63(R2)"
  //-------------------------------------------------
  always @(posedge clock) begin
    case(state)
      //------------------------------------------------
      // ldi R2, 0x78
      //------------------------------------------------
      LDI_T0: begin
        // T0: PCout, MARin, IncPC, Zin
        incPC <= 1;
        e_MAR <= 1;
        e_Z <= 1;
        BusDataSelect <= 5'b10100; // PCout
        state <= LDI_T0_WAIT;
      end
      LDI_T0_WAIT: begin
        incPC <= 0; e_MAR <= 0; e_Z <= 0;
        BusDataSelect <= 5'b00000;
        state <= LDI_T1;
      end
      LDI_T1: begin
        // T1: Zlowout -> PCin, read memory
        //e_PC <= 1;
        ram_read <= 1;
        BusDataSelect <= 5'b10011; // Zlowout
        state <= LDI_T1_WAIT;
      end
      LDI_T1_WAIT: begin
        //e_PC <= 0;
        // Now capture the instruction from RAM
        MDR_read <= 1;
        ram_read <= 0;
        e_MDR <= 1;
        BusDataSelect <= 5'b00000;
        state <= LDI_T2;
      end
      LDI_T2: begin
        // T2: MDRout -> IR
        e_IR <= 1;
        BusDataSelect <= 5'b10101; // MDRout
        state <= LDI_T3;
      end
      LDI_T3: begin
        // For ldi, we want 0 + immediate => Z
        // So let's load 0 into Y from R0 (assuming IR[22..19]=0 => R0).
        e_IR <= 0;
        Grb <= 1;   // select Rb => IR[22..19] = 0 if opcode uses R0 as base
        BAout <= 1; // force zero if R0 is selected
        e_Y <= 1;
        BusDataSelect <= 5'b00000; // R0 out
        state <= LDI_T4;
      end
      LDI_T4: begin
        // imm_sel=1 => ALU uses sign-extended immediate (0x78)
        Grb <= 0; BAout <= 0; e_Y <= 0;
        imm_sel <= 1;
        ALU_op <= 4'b0011; // ADD
        e_Z <= 1;
        // No need to drive the bus for ALU_B; imm_sel=1 picks C_sign_ext
        BusDataSelect <= 5'b00000; // bus doesn’t matter for ALU_B in this design
        state <= LDI_T5;
      end
      LDI_T5: begin
        // Zlowout -> R2
        e_Z <= 0;
        imm_sel <= 0;
        Gra <= 1;  // IR[26..23] = 2 => R4
        e_Rin <= 1;
        BusDataSelect <= 5'b10011; // Zlowout
        state <= LDI_DONE;
      end
      LDI_DONE: begin
        Gra <= 0; e_Rin <= 0;
        BusDataSelect <= 5'b00000;
        // R4 now holds 0x54

      end
      
      
      DONE: begin
        $finish;
      end
      
      default: state <= DONE;
    endcase
  end

endmodule
