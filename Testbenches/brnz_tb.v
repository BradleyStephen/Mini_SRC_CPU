`timescale 1ns/10ps
module brnz_tb;
//48A80000 hex code

  // Clock and reset signals
  reg clear, clock, incPC;
  
  // Register enable signals
  reg e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MDR, e_MAR, e_GP, e_OutPort, e_InPort;
  reg e_RA, e_CON_FF;
  
  // RAM control signals
  reg ram_read, ram_write;
  
  // Memory and ALU signals (Mdatain is driven by your RAM)
  wire [31:0] Mdatain;
  reg MDR_read;
  
  reg [3:0] ALU_op;
  reg [4:0] BusDataSelect;
  
  // Select and encode control signals
  reg Gra, Grb, Grc, e_Rin, e_Rout, BAout;
  
  // ALU operand multiplexer control signal
  reg imm_sel;
  
  // FSM state definition
  reg [4:0] state;
  localparam 
      // Instruction Fetch States (T0-T2)
      BR_T0      = 5'd0,  
      BR_T0_WAIT = 5'd1,
      BR_T1      = 5'd2,
      BR_T1_WAIT = 5'd3,
      BR_T2      = 5'd4,
      // Branch-Specific Execution States
      BR_T3      = 5'd5,
      BR_T4      = 5'd6,
      BR_T5      = 5'd7,
      BR_T6      = 5'd8,
      BR_T7      = 5'd9,
      BR_T8      = 5'd10,
      DONE       = 5'd11;
  
  // Instantiate the datapath (which includes the con_ff_logic)
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
  
  // Clock generation
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
    state = BR_T0;
    
    // Deassert reset after 50 ns
    #50 clear = 0;
    
    // IMPORTANT:
    // 1) Ensure your RAM or IR is loaded with the brnz opcode 
    //    (i.e., IR[20..19] = 2'b01).
    // 2) Preload R1 with a NON-ZERO value to see the branch taken.
  end
  
  // Main FSM
  always @(posedge clock) begin
    case(state)
      // Instruction Fetch
      BR_T0: begin
        incPC <= 1;
        e_MAR <= 1;
        e_Z <= 1;
        BusDataSelect <= 5'b10100; // PCout
        state <= BR_T0_WAIT;
      end
      BR_T0_WAIT: begin
        incPC <= 0; 
        e_MAR <= 0; 
        e_Z <= 0;
        BusDataSelect <= 5'b00000;
        state <= BR_T1;
      end
      BR_T1: begin
        ram_read <= 1;
        BusDataSelect <= 5'b10011; // Zlowout
        state <= BR_T1_WAIT;
      end
      BR_T1_WAIT: begin
        MDR_read <= 1;
        ram_read <= 0;
        e_MDR <= 1;
        BusDataSelect <= 5'b00000;
        state <= BR_T2;
      end
      BR_T2: begin
        e_IR <= 1;
        BusDataSelect <= 5'b10101; // MDRout
        state <= BR_T3;
      end
      
      // Branch Execution
      BR_T3: begin
        e_IR <= 0;    
        Gra <= 1;     // Assume IR[26..23] = 1 => R1
        e_Rout <= 1;  
        e_CON_FF <= 1; // Evaluate branch condition
        state <= BR_T4;
      end
      BR_T4: begin
        Gra <= 0; 
        e_Rout <= 0;
        e_CON_FF <= 0;
        e_Y <= 1;
        BusDataSelect <= 5'b10100; // PCout -> Y
        state <= BR_T5;
      end
      BR_T5: begin
        e_Y <= 0;
        imm_sel <= 1;       // sign-extended offset
        ALU_op <= 4'b0011;  // ADD
        e_Z <= 1;           
        BusDataSelect <= 5'b01100; // offset
        state <= BR_T6;
      end
		BR_T6: begin
        // T6: Zlowout -> PC (if branch condition is met, load branch target)
        e_Z <= 0;
        imm_sel <= 0;
        e_PC <= 1;     
        BusDataSelect <= 5'b10011; // Select branch target output (adjust as needed)
        state <= BR_T7;
      end
		BR_T7: begin
			e_PC <= 0;
            incPC <= 1;    // Load computed branch target into PC
			BusDataSelect <= 5'b00000;
			state <= BR_T8;
		end
        BR_T8: begin
			e_PC <= 0;
            incPC <= 0;    // Load computed branch target into PC
			BusDataSelect <= 5'b00000;
			state <= DONE;
		end

      
      DONE: begin
        // Deassert all signals and finish simulation
        //incPC <= 0;
        BusDataSelect <= 5'b00000;
        $finish;
      end
      
      default: state <= DONE;
    endcase
  end

endmodule
