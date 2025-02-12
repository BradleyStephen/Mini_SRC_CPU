`timescale 1ns/10ps
module datapath_tb_shra;

	reg clear, clock, incPC;
	reg [3:0] GP_addr;
	reg e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MDR, e_MAR, e_GP;
	
	reg [31:0] Mdatain;
	reg MDR_read;
	
	reg [3:0] alu_op;
	
	reg [4:0] BusDataSelect;
	
	parameter Default = 4'b0000, Reg_load1a = 4'b0001, Reg_load1b = 4'b0010, Reg_load2a = 4'b0011,
	Reg_load2b = 4'b0100, Reg_load3a = 4'b0101, Reg_load3b = 4'b0110, T0 = 4'b0111,
	T1 = 4'b1000, T2 = 4'b1001, T3 = 4'b1010, T4 = 4'b1011, T5 = 4'b1100;
	
	reg [3:0] Present_state = Default;
	
	datapath DUT(
		.clear(clear),
		.clock(clock),
		.incPC(incPC),
		.GP_addr(GP_addr),
		.Mdatain(Mdatain),
		.MDR_read(MDR_read),
		.e_PC(e_PC),
		.e_IR(e_IR),
		.e_Y(e_Y),
		.e_Z(e_Z),
		.e_HI(e_HI),
		.e_LO(e_LO),
		.e_MDR(e_MDR),
		.e_MAR(e_MAR),
		.e_GP(e_GP),
		.ALU_op(alu_op),
		.BusDataSelect(BusDataSelect)
	);
	
	// Clock generation
	initial begin
		clock = 0;
		clear = 1;
	end
	
	always #10 begin
		clock = ~clock;
	end
	
	always @(posedge clock) begin // Finite state machine; executes on clock rising edge
		case (Present_state)
			Default : Present_state = Reg_load1a;
			Reg_load1a : Present_state = Reg_load1b;
			Reg_load1b : Present_state = Reg_load2a;
			Reg_load2a : Present_state = Reg_load2b;
			Reg_load2b : Present_state = Reg_load3a;
			Reg_load3a : Present_state = Reg_load3b;
			Reg_load3b : Present_state = T0;
			T0 : Present_state = T1;
			T1 : Present_state = T2;
			T2 : Present_state = T3;
			T3 : Present_state = T4;
			T4 : Present_state = T5;
		endcase
	end
	
	always @(Present_state) begin // Do the required job in each state
		case (Present_state) // Assert the required signals in each clock cycle
			Default: begin
				clear <= 0;
				BusDataSelect = 5'b00000; GP_addr = 4'b0000; // Initialize the signals
				e_MAR <= 0; e_Z <= 0; e_PC <= 0; e_MDR <= 0; e_IR <= 0; e_Y <= 0; e_GP = 0; e_HI <= 0; e_LO <= 0;
				incPC <= 0; MDR_read <= 0; alu_op <= 4'b1100; // SHRA opcode
				Mdatain <= 32'h000000000;
			end
			Reg_load1a: begin
				Mdatain <= 32'hFFFFFF88; // Negative signed value (-120 in two's complement)
				MDR_read = 0; e_MDR = 0;
				MDR_read <= 1; e_MDR <= 1;
				#20 MDR_read <= 0; e_MDR <= 0;
			end
			Reg_load1b: begin
				BusDataSelect <= 5'b10101; GP_addr <= 4'b0011; e_GP = 1;
				#20 e_GP <= 0; // Initialize R3 with the value 0xFFFFFF88 (-120)
			end
			Reg_load2a: begin
				Mdatain <= 32'h00000002;
				MDR_read <= 1; e_MDR <= 1;
				#20 MDR_read <= 0; e_MDR <= 0;
			end
			Reg_load2b: begin
				BusDataSelect <= 5'b10101; GP_addr <= 4'b0111; e_GP = 1;
				#20 e_GP <= 0; // Initialize R7 with the value 0x02 (shift amount)
			end
			Reg_load3a: begin
				Mdatain <= 32'h00000000;
				MDR_read <= 1; e_MDR <= 1;
				#20 MDR_read <= 0; e_MDR <= 0;
			end
			Reg_load3b: begin
				BusDataSelect <= 5'b10101; GP_addr <= 4'b0100; e_GP = 1;
				#20 e_GP <= 0; // Initialize R4 to store result
			end
			T0: begin
				BusDataSelect <= 5'b10100; e_MAR <= 1; incPC <= 1; e_Z <= 1;
				#20 e_MAR <= 0; incPC <= 0; e_Z <= 0;
			end
			T1: begin
				BusDataSelect <= 5'b10011; e_PC <= 1; MDR_read <= 1; e_MDR <= 1;
				Mdatain <= 32'h2A318000; // Opcode for “SHRA R4, R3, R7”
				#20 e_PC <= 0; MDR_read <= 0; e_MDR <= 0;
			end
			T2: begin
				BusDataSelect <= 5'b10101; e_IR <= 1;
				#20 e_IR <= 0;
			end
			T3: begin
				BusDataSelect <= 5'b00011; e_Y <= 1;
				#20 e_Y <= 0;
			end
			T4: begin
				BusDataSelect <= 5'b00111; alu_op = 4'b1100; e_Z <= 1; // SHRA opcode
				#20 e_Z <= 0;
			end
			T5: begin
				BusDataSelect <= 5'b10011; GP_addr <= 4'b0100; e_GP <= 1;
				#20 e_GP <= 0;
			end
		endcase
	end

endmodule
