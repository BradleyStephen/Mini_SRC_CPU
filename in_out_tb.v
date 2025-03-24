`timescale 1ns/10ps
module datapath_tb_inout;

  // Clock and reset signals
  reg clear, clock, incPC;
  
  // Register enable signals for PC, IR, Y, Z, HI, LO, MDR, MAR, GP
  reg e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MDR, e_MAR, e_GP, e_OutPort, e_InPort;
  
  // Memory and ALU signals
  reg [31:0] Mdatain;
  reg MDR_read;
  
  reg [3:0] ALU_op;
  
  reg [4:0] BusDataSelect;

  
  // Control signals for Select Encode (manually driven)
  reg Gra, Grb, Grc;
  reg e_Rin, e_Rout, BAout;
  
  reg imm_sel;
  reg ram_read, ram_write;
  //reg MDR_read;

  // I/O data
  reg [31:0] ExternalData;

  // State machine
  parameter Default = 0, T0 = 1, T1 = 2, T2 = 3, T3 = 4;
  reg [3:0] Present_state = Default;

// Instantiate the datapath (adjust port mapping as needed)
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
    clear = 1;
  end

  always #20 clock = ~clock;

  // FSM state progression
  always @(posedge clock) begin
    case (Present_state)
      Default: Present_state = T0;
      T0: Present_state = T1;
      T1: Present_state = T2;
      T2: Present_state = T3;
    endcase
  end

  // Drive control signals based on the current state
  always @(Present_state) begin
    
    case (Present_state)
		Default: begin
			clear <= 0;
			e_PC = 0; e_IR = 0; e_Y = 0; e_Z = 0; e_HI = 0; e_LO = 0; e_MDR = 0; e_MAR = 0; e_GP = 0;
			 incPC = 0;
			 MDR_read = 0;
			 BusDataSelect = 5'd0;
			 Gra = 0; Grb = 0; Grc = 0;
			 e_Rin = 0; e_Rout = 0; BAout = 0;
			 Mdatain = 32'd0;
			 ram_read = 0; ram_write = 0;
			 imm_sel = 0;
		end

      // T0: PCout, MARin, IncPC, Zin
      T0: begin
        BusDataSelect <= 5'b10100; e_MAR <= 1; e_Z <= 1;
        #40 e_MAR <= 0; e_Z <= 0;
      end

      // T1: Zlowout, PCin, Read, MDRin (fetch instruction)
      T1: begin
        BusDataSelect <= 5'b10011; MDR_read <= 1; e_MDR <= 1;
        #40 e_MDR <= 0;
      end

      // T2: MDRout, IRin
      T2: begin
        BusDataSelect <= 5'b10101; e_IR <= 1;
        #40 e_IR <= 0;
      end

      // -------------------------------
      // T3: Execute I/O instruction
      // Case A: OUT R6
      T3: begin
        // Output R6 to output port
        Gra <= 1; e_Rout <= 1; e_OutPort <= 1;
        #40 Gra <= 0; e_Rout <= 0; e_OutPort <= 0;

        // Uncomment below to test the IN R3 case
        /*
        ExternalData <= 32'hBEEF1234; // simulate external input
        e_InPort <= 1; Gra <= 1; e_Rin <= 1; e_GP <= 1;
        #40 e_InPort <= 0; Gra <= 0; e_Rin <= 0; e_GP <= 0;
        */
      end

    endcase
  end

endmodule