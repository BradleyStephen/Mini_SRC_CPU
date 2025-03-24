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
  // Note: Mdatain is driven by the datapath (via RAM), so declare it as a wire.
  wire [31:0] Mdatain;
  reg MDR_read;
  
  reg [3:0] ALU_op;
  
  reg [4:0] BusDataSelect;
  
  // Select and encode control signals
  reg Gra, Grb, Grc, e_Rin, e_Rout, BAout;
  
  // ALU operand multiplexer control signal
  reg imm_sel;
  
  // FSM state definition – we use a 4-bit state encoding.
  reg [3:0] state;
  localparam 
      RESET    = 4'd0,
      T0       = 4'd1,  // T0: PCout, MARin, IncPC, Zin
      T0_WAIT  = 4'd2,  // Wait for signals to settle
      T1       = 4'd3,  // T1: Zlowout, PCin, initiate Read (start memory read)
      T1_WAIT  = 4'd4,  // Wait cycle to allow RAM output to become valid; then load MDR
      T2       = 4'd5,  // T2: MDRout, IRin
      T3       = 4'd6,  // T3: Grb, BAout, Yin
      T4       = 4'd7,  // T4: Cout, ADD, Zin
      T5       = 4'd8,  // T5: Zlowout, MARin
      T5_WAIT  = 4'd9,  // Wait cycle to deassert signals
      T6       = 4'd10, // T6: Initiate second memory read (Read)
      T6_WAIT  = 4'd11, // Wait cycle then capture data into MDR (MDRin)
      T7       = 4'd12, // T7: MDRout, Gra, Rin
      T7_WAIT  = 4'd13, // T7: MDRout, Gra, Rin
      DONE     = 4'd14; // End simulation
  
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
  
  // Clock generation: 20 ns period using a repeat loop (avoiding forever syntax)
  initial begin
    clock = 0;
    repeat (250) begin
      #10 clock = ~clock;
    end
  end
  
  // Initial reset and control signal initialization
  initial begin
    // Assert reset and initialize control signals
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
  end
  
  // FSM-driven test sequence for ld instruction (Case 1: ld R4, 0x54)
  always @(posedge clock) begin
    case(state)
      RESET: begin
         // Hold reset for one cycle.
         clear <= 1;
         state <= T0;
      end
      
      T0: begin
         // T0: PCout, MARin, IncPC, Zin.
         clear <= 0;
         incPC <= 1;
         e_MAR <= 1;
         e_Z <= 1;
         BusDataSelect <= 5'b10100;  // PC opcode
         state <= T0_WAIT;
      end
      
      T0_WAIT: begin
         // Deassert signals after T0.
         incPC <= 0;
         e_MAR <= 0;
         e_Z <= 0;
         BusDataSelect <= 5'b00000;
         state <= T1;
      end
      
      T1: begin
         // T1: Zlowout, PCin, initiate Read.
         // Output the lower half of Z onto the bus and load PC.
         e_PC <= 1;            // PCin asserted
         ram_read <= 1;        // Start memory read operation
         BusDataSelect <= 5'b10011; // Zlow opcode
         state <= T1_WAIT;
      end
      
      T1_WAIT: begin
         // Wait one cycle for the RAM to produce valid data.
         e_PC <= 0;
         // Now assert MDRin to capture RAM output.
         MDR_read <= 1;
         e_MDR <= 1;
         BusDataSelect <= 5'b00000;
         state <= T2;
      end
      
      T2: begin
         // T2: MDRout, IRin.
         e_IR <= 1;          // Load IR
         BusDataSelect <= 5'b10101; // MDR opcode
         state <= T3;
      end
      
      T3: begin
         // T3: Grb, BAout, Yin.
         e_IR <= 0;          // Deassert previous signal
         Grb <= 1;
         BAout <= 1;
         e_Y <= 1;           // Load Y with the register B output
         BusDataSelect <= 5'b00000; // Arbitrary code for Grb output (adjust as needed)
         state <= T4;
      end
      
      T4: begin
         // T4: Cout, ADD, Zin.
         Grb <= 0; BAout <= 0; e_Y <= 0;  // Deassert T3 signals
         imm_sel <= 1;       // Select the constant (sign-extended) as ALU_B input (Cout)
         ALU_op <= 4'b0011;  // Assume 0000 is the ADD operation
         e_Z <= 1;           // Load Z with the ALU result
         BusDataSelect <= 5'b01100; // Arbitrary code for constant output (Cout)
         state <= T5;
      end
      
      T5: begin
         // T5: Zlowout, MARin.
         e_Z <= 0;
         imm_sel <= 0;
         e_MAR <= 1;         // Load MAR with the effective address from Zlow
         BusDataSelect <= 5'b10011; // Zlow opcode
         state <= T5_WAIT;
      end
      
      T5_WAIT: begin
         e_MAR <= 0;
         BusDataSelect <= 5'b00000;
         state <= T6;
      end
      
      T6: begin
         // T6: Initiate a second memory read.
         ram_read <= 1;
         MDR_read <= 0;
         e_MDR <= 0;
         state <= T6_WAIT;
      end
      
      T6_WAIT: begin
         // Wait one cycle for memory read; then capture the data.
         ram_read <= 1; // May remain asserted for this cycle
         MDR_read <= 1;
         e_MDR <= 1;
         state <= T7;
      end
      
      T7: begin
        // T7: MDRout, Gra, Rin.
        ram_read <= 0;
        MDR_read <= 0;
        e_MDR <= 0;
        Gra <= 1;        // Destination = IR[26..23]
        e_Rin <= 1;      // Enable register file write
        BusDataSelect <= 5'b10101; // MDRout
        state <= T7_WAIT;
      end

      T7_WAIT: begin
        // Deassert signals, let the clock edge pass
        Gra <= 0;
        e_Rin <= 0;
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
