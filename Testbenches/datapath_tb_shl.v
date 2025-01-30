`timescale 1ns/10ps
module datapath_tb_shl;

	reg PC_BusSelect, Zlow_BusSelect, MDR_BusSelect, R2_BusSelect, R3_BusSelect, R4_BusSelect, R5_BusSelect; // add any other signals to see _enable your simulation
	reg MAR_enable, Z_enable, PC_enable, MDR_enable, IR_enable, Y_enable, HI_enable, LO_enable, alu_enable;
	reg incPC, Read, R1_enable, R2_enable, R3_enable, R4_enable, R5_enable;
	reg Clock, Clear;
	reg [31:0] Mdatain;
	reg [5:0] alu_opcode;
	parameter Default = 4'b0000, Reg_load1a = 4'b0001, Reg_load1b = 4'b0010, Reg_load2a = 4'b0011,
	Reg_load2b = 4'b0100, Reg_load3a = 4'b0101, Reg_load3b = 4'b0110, T0 = 4'b0111,
	T1 = 4'b1000, T2 = 4'b1001, T3 = 4'b1010, T4 = 4'b1011, T5 = 4'b1100;
	reg [3:0] Present_state = Default;
	
	parameter add=5'b00000, sub=5'b00001, AND=5'b00010, OR=5'b00011, NOT=5'b00100, mul=5'b00101, div=5'b00110, rol=5'b00111, ror=5'b01000, shr=5'b01001, shra=5'b01010,
	shl=5'b01011, neg=5'b01100;
	
	DataPath DUT(
		.w_clock(Clock),
		.w_clear(Clear),
		.w_IncPC(incPC),
		.e_R1(R1_enable),
		.e_R2(R2_enable),
		.e_R3(R3_enable),
		.e_R4(R4_enable),
		.e_R5(R5_enable),
		.e_MAR(MAR_enable),
		.e_Z(Z_enable),
		.e_PC(PC_enable),
		.e_MDR(MDR_enable),
		.e_IR(IR_enable),
		.e_Y(Y_enable),
		.e_HI(HI_enable),
		.e_LO(LO_enable),
		.s_PC(PC_BusSelect),
		.s_Zlow(Zlow_BusSelect),
		.s_MDR(MDR_BusSelect),
		.s_R2(R2_BusSelect),
		.s_R3(R3_BusSelect),
		.s_R4(R4_BusSelect),
		.s_R5(R5_BusSelect),
		.w_read(Read),
		.opcode(alu_opcode),
		.e_alu(alu_enable),
		.w_Mdatain(Mdatain)
	);
	
	// add test logic here
	initial begin
		Clock = 0;
		Clear = 0;
	end
	
	always #10 begin
		Clock = ~Clock;
	end

	always @(posedge Clock) // f_enableite state mach_enablee; if clock ris_enableg-edge
	begin
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

	always @(Present_state) // do the required job _enable each state
	begin
		case (Present_state) // assert the required signals _enable each clock cycle
			Default: begin
				PC_BusSelect <= 0; Zlow_BusSelect <= 0; MDR_BusSelect <= 0; // initialize the signals
				R2_BusSelect <= 0; R3_BusSelect <= 0; R4_BusSelect <= 0; R5_BusSelect <= 0; MAR_enable <= 0; Z_enable <= 0;
				PC_enable <=0; MDR_enable <= 0; IR_enable <= 0; Y_enable <= 0; LO_enable <= 0; HI_enable <= 0; alu_enable <= 0;
				incPC <= 0; Read <= 0;
				R1_enable <= 0; R2_enable <= 0; R3_enable <= 0; R4_enable <= 0; R5_enable <= 0; Mdatain <= 32'h00000000;
			end
			Reg_load1a: begin
				Mdatain <= 32'h00000012;
				Read = 0; MDR_enable = 0; // the first zero is there for completeness
				Read <= 1; MDR_enable <= 1; // and the first 10ns might not be needed depend_enableg on your
				#15 Read <= 0; MDR_enable <= 0; // implementation; same goes for the other states
			end
			Reg_load1b: begin
				MDR_BusSelect <= 1; R2_enable <= 1;
				#15 MDR_BusSelect <= 0; R2_enable <= 0; // initialize R2 with the value $12
			end
			Reg_load2a: begin
				Mdatain <= 32'h00000002;
				Read <= 1; MDR_enable <= 1;
				#15 Read <= 0; MDR_enable <= 0;
			end
			Reg_load2b: begin
				MDR_BusSelect <= 1; R3_enable <= 1;
				#15 MDR_BusSelect <= 0; R3_enable <= 0; // initialize R3 with the value $14
			end
			Reg_load3a: begin
				Mdatain <= 32'h00000018;
				Read <= 1; MDR_enable <= 1;
				#15 Read <= 0; MDR_enable <= 0;
			end
			Reg_load3b: begin
				MDR_BusSelect <= 1; R1_enable <= 1;
				#15 MDR_BusSelect <= 0; R1_enable <= 0; // initialize R1 with the value $18
			end
			T0: begin // see if you need to de-assert these signals
				PC_BusSelect <= 1; MAR_enable <= 1; incPC <= 1; Z_enable <= 1;
				#15 PC_BusSelect <= 0; MAR_enable <= 0; incPC <= 0; Z_enable <= 0;
			end
			T1: begin
				Zlow_BusSelect <= 1; PC_enable <= 1; Read <= 1; MDR_enable <= 1;
				Mdatain <= 32'h28918000; // opcode for “and R1, R2, R3”
				#15 Zlow_BusSelect <= 0; PC_enable <= 0; MDR_enable <= 0;
			end
			T2: begin
				MDR_BusSelect <= 1; IR_enable <= 1;
				#15 MDR_BusSelect <= 0; IR_enable <= 0;
			end
			T3: begin
				R2_BusSelect <= 1; Y_enable <= 1;
				#15 R2_BusSelect <= 0; Y_enable <= 0;
			end
			T4: begin
				R3_BusSelect <= 1; alu_opcode <= shl; Z_enable <= 1; alu_enable <= 1;
				#20 R3_BusSelect <= 0; Z_enable <= 0; alu_enable <= 0;
			end
			T5: begin
				Zlow_BusSelect <= 1; R1_enable <= 1; LO_enable <= 1;
				#15 Zlow_BusSelect <= 0; R1_enable <= 0; LO_enable <= 0;
			end
		endcase
	end
endmodule