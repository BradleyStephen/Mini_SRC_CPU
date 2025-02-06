module datapath(
	input wire clear, clock, incPC,
	
	//register write enable signals
	input wire e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MDR, e_MAR, e_GP,
	
	input wire [3:0] reg_addr,
	
	input wire [31:0] Mdatain,
	input wire read,
	
	//data signals
	input wire [4:0] BusDataSelect

);

	wire [31:0] GP_r0, GP_r1, GP_r2, GP_r3, GP_r4, GP_r5, GP_r6, GP_r7, GP_r8, GP_r9, GP_r10, GP_r11, GP_r12, GP_r13, GP_r14, GP_r15;
	
	wire [31:0] BusData, BusIn_R0, BusIn_R1, BusIn_R2, BusIn_R3, BusIn_R4, BusIn_R5, BusIn_R6, BusIn_R7;
	wire [31:0] BusIn_R8, BusIn_R9, BusIn_R10, BusIn_R11, BusIn_R12, BusIn_R13, BusIn_R14, BusIn_R15;
	wire [31:0] BusIn_HI, BusIn_LO, BusIn_Zhigh, BusIn_Zlow, BusIn_PC, BusIn_MDR;
	
	//general purpose 32 bit registers
	register_file GP_reg (
		clear,
		clock,
		reg_addr,
		e_GP,
		BusData,
		GP_r0, GP_r1, GP_r2, GP_r3,
		GP_r4, GP_r5, GP_r6, GP_r7,
		GP_r8, GP_r9, GP_r10, GP_r11,
		GP_r12, GP_r13, GP_r14, GP_r15
	);
	
	assign BusIn_R0 = GP_r0;
	assign BusIn_R1 = GP_r1;
	assign BusIn_R2 = GP_r2;
	assign BusIn_R3 = GP_r1;
	assign BusIn_R4 = GP_r4;
	assign BusIn_R5 = GP_r5;
	assign BusIn_R6 = GP_r6;
	assign BusIn_R7 = GP_r7;
	assign BusIn_R8 = GP_r8;
	assign BusIn_R9 = GP_r9;
	assign BusIn_R10 = GP_r10;
	assign BusIn_R11 = GP_r11;
	assign BusIn_R12 = GP_r12;
	assign BusIn_R13 = GP_r13;
	assign BusIn_R14 = GP_r14;
	assign BusIn_R15 = GP_r15;
	
	//instruction registers
	//program_counter PC(clear, clock, e_PC, inc_PC, BusData, BusIn_PC);
	register_32 IR(clear, clock, e_IR, BusData, BusIn_IR);
	
	//ALU and related registers
	//register_32 Y(clear, clock, e_Y, BusData, toALU);	
	register_64 Z(clear, clock, e_Z, BusData, BusIn_Zlow, BusIn_zhigh);
	
	register_32 HI(clear, clock, e_HI, BusData, BusIn_HI);
	register_32 LO(clear, clock, e_LO, BusData, BusIn_LO);

	//memory "gateway"
	//register_32 MAR(clear, clock, e_MAR, BusData, toMemory);
	mdr MDR(clear, clock, e_MDR, read, BusData, Mdatain, BusIn_MDR);
	
	//bus
	bus bus(.data_select(BusDataSelect), .BusMuxIn_R0(BusIn_R0), .BusMuxIn_R1(BusIn_R1), .BusMuxIn_R2(BusIn_R2), .BusMuxIn_R3(BusIn_R3),
		.BusMuxIn_R4(BusIn_R4), .BusMuxIn_R5(BusIn_R5), .BusMuxIn_R6(BusIn_R6), .BusMuxIn_R7(BusIn_R7), .BusMuxIn_R8(BusIn_R8), .BusMuxIn_R9(BusIn_R9),
		.BusMuxIn_R10(BusIn_R10), .BusMuxIn_R11(BusIn_R11), .BusMuxIn_R12(BusIn_R12), .BusMuxIn_R13(BusIn_R13), .BusMuxIn_R14(BusIn_R14),
		.BusMuxIn_R15(BusIn_R15), .BusMuxIn_HI(BusIn_HI), .BusMuxIn_LO(BusIn_LO), .BusMuxIn_Zhigh(BusIn_Zhigh), .BusMuxIn_Zlow(BusIn_Zlow),
		.BusMuxIn_PC(BusIn_PC), .BusMuxIn_MDR(BusIn_MDR), .BusMuxOut(BusData));
	
endmodule
