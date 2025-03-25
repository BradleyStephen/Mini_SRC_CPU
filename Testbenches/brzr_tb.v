`timescale 1ns/10ps
module brzr_tb;
//48A00027 test code
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
  
  // FSM state definition
  reg [4:0] state;
  localparam 
      // Instruction Fetch States (T0-T2)
      BR_T0      = 5'd0,  // T0: PCout, MARin, IncPC, Zin
      BR_T0_WAIT = 5'd1,
      BR_T1      = 5'd2,  // T1: Read memory; Zlowout drives PCin
      BR_T1_WAIT = 5'd3,
      BR_T2      = 5'd4,  // T2: MDRout -> IR
      // Branch-Specific Execution States
      BR_T3      = 5'd5,  // T3: Gra, Rout, CONin (evaluate branch condition)
      BR_T4      = 5'd6,  // T4: PCout, Yin (load PC into Y)
      BR_T5      = 5'd7,  // T5: Cout, ADD, Zin (compute branch target = PC + 1 + sign-extended offset)
      BR_T6      = 5'd8,  // T6: Zlowout, CON -> PCin (load branch target into PC if branch taken)
		BR_T7		  = 5'd9,
      BR_T8 	  = 5'd10,	
      DONE       = 5'd11;
  
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
  
  // Clock generation: 20 ns period using a repeat loop
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
  end
  
  //-------------------------------------------------
  // FSM: First perform the instruction fetch (T0–T2), then branch execution
  //-------------------------------------------------
  always @(posedge clock) begin
    case(state)
      ////////////
      // Instruction Fetch for branch instruction
      ////////////
      BR_T0: begin
        // T0: PCout, MARin, IncPC, Zin
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
        // T1: Zlowout -> PCin, initiate memory read
        ram_read <= 1;
        BusDataSelect <= 5'b10011; // Zlowout
        state <= BR_T1_WAIT;
      end
      BR_T1_WAIT: begin
        // Capture the instruction from memory into MDR
        MDR_read <= 1;
        ram_read <= 0;
        e_MDR <= 1;
        BusDataSelect <= 5'b00000;
        state <= BR_T2;
      end
      BR_T2: begin
        // T2: MDRout -> IR (fetch complete)
        e_IR <= 1;
        BusDataSelect <= 5'b10101; // MDRout
        state <= BR_T3;
      end
      
      ////////////
      // Branch Instruction Execution
      ////////////
      BR_T3: begin
        // T3: Evaluate branch condition
        // For example, drive R1 (the branch register) onto the bus.
        e_IR <= 0;    // Deassert IR load from fetch
        Gra <= 1;     // Select branch register (e.g., R1)
        e_Rout <= 1;  // Drive register output onto bus
        e_CON_FF <= 1; // Assert CONin to capture branch condition
        state <= BR_T4;
      end
      BR_T4: begin
        // T4: Output PC onto Y to prepare for addition (PC + 1 + offset)
        Gra <= 0; 
        e_Rout <= 0;
        e_CON_FF <= 0;
        e_Y <= 1;
        BusDataSelect <= 5'b10100; // PCout to Y
        state <= BR_T5;
      end
      BR_T5: begin
        // T5: ALU operation: add sign-extended branch offset to Y
        e_Y <= 0;
        imm_sel <= 1;       // Select the sign-extended immediate (branch offset)
        ALU_op <= 4'b0011;  // ADD operation (adjust as needed)
        e_Z <= 1;           // Load ALU result into Z
        BusDataSelect <= 5'b01100; // Select constant output (branch offset)
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
