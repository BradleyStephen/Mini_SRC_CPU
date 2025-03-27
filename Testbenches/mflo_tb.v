`timescale 1ns/10ps
module mflo_tb;

	reg clear, clock, incPC;

	// enable signals
	reg e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MDR, e_MAR, e_GP, e_OutPort, e_InPort;
	reg e_RA, e_CON_FF;

	// RAM control signals
	reg ram_read, ram_write;

	// Memory and ALU signals (Mdatain is driven by RAM)
	wire [31:0] Mdatain;
	reg MDR_read;
	
	reg [3:0] ALU_op;
	reg [4:0] BusDataSelect;
      //inport data connection foor simulation
    reg [31:0] in_data;

	// Select and encode control signals
	reg Gra, Grb, Grc, e_Rin, e_Rout, BAout;

	// ALU operand multiplexer control signal
	reg imm_sel;
	
	parameter Default = 4'b0000, PREFILL_HI_a = 4'b0001, PREFILL_HI_b = 4'b0010, T0 = 4'b0011,
	T1 = 4'b0100, T2 = 4'b0101, T3 = 4'b0110, T4 = 4'b0111;
	
	reg [3:0] Present_state = Default;
	
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
    .imm_sel(imm_sel),
    .in_port_sim(in_data)
  );
  
  // Clock generation
	initial begin
		clock = 0;
		clear = 1;
	end
	
	always #10 begin
		clock = ~clock;
	end
	
	always @(posedge clock) begin
		case (Present_state)
			Default : Present_state = PREFILL_HI_a;
			PREFILL_HI_a : Present_state = PREFILL_HI_b;
			PREFILL_HI_b : Present_state = T0;
			T0 : Present_state = T1;
			T1 : Present_state = T2;
			T2 : Present_state = T3;
			T3 : Present_state = T4;
		endcase
	end

    initial begin
    // Adjust the hierarchical name if needed.
    in_data = 32'h00000077;
    end
	
	always @(Present_state) begin
		case (Present_state)
			Default: begin
				clear <= 0;
				BusDataSelect = 5'b00000; ALU_op <= 4'b0000; incPC <= 0;
				e_MAR <= 0; e_Z <= 0; e_PC <= 0; e_MDR <= 0; e_IR <= 0; e_Y <= 0; e_GP = 0; e_HI <= 0; e_LO <= 0;
				e_OutPort <= 0; e_InPort <= 0; e_RA <= 0; e_CON_FF <= 0;
				ram_read <= 0; ram_write <= 0;
				MDR_read <= 0; Gra <= 0; Grb <= 0; Grc <= 0; e_Rin <= 0; e_Rout <= 0; BAout <= 0; imm_sel <= 0;
			end
			PREFILL_HI_a: begin
                e_InPort <= 1;
                BusDataSelect <= 5'b10110;
                #20 e_InPort <= 0;
			end
			PREFILL_HI_b: begin
				e_LO <= 1;
				#20 e_LO <= 0;
			end
			T0: begin // move to next instruction location (incPC) and place in MAR
				e_MAR <= 1;
				BusDataSelect <= 5'b10100;
				#20 e_MAR <= 0;
			end
			T1: begin // get instruction from memory using MDR
				ram_read <= 1;
				#20 ram_read <= 0;
			end
			T2: begin // place instruction from MDR in IR
				MDR_read <= 1; e_MDR <= 1;
				#20 MDR_read <= 0; e_MDR <= 0;
			end
			T3: begin // place instruction from MDR in IR
				e_IR <= 1;
				BusDataSelect <= 5'b10101;
				#20 e_IR <= 0; BusDataSelect <= 5'b00000;
			end
			T4: begin // copy data from HI to register Ra
				BusDataSelect <= 5'b10001; Gra <= 1; e_Rin <= 1;
				#20 Gra <= 0; e_Rin <= 0;
			end
		endcase
	end
	
endmodule