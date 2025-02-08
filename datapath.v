module datapath(
	input wire clear, clock, incPC,
	
	//register write enable signals
	input wire e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MDR, e_MAR, e_GP,
	
	input wire [3:0] GP_addr,
	
	input wire [31:0] Mdatain,
	input wire MDR_read,
	
	input wire [3:0] ALU_op,
	
	//data signals
	input wire [4:0] BusDataSelect

);
	
	wire [31:0] ALU_A;
	wire [63:0] ALU_C;
	wire isZero;
	
	wire [31:0] toControl;
	wire [31:0] Maddrout;
	
	wire [31:0] BusData, BusIn_R0, BusIn_R1, BusIn_R2, BusIn_R3, BusIn_R4, BusIn_R5, BusIn_R6, BusIn_R7;
	wire [31:0] BusIn_R8, BusIn_R9, BusIn_R10, BusIn_R11, BusIn_R12, BusIn_R13, BusIn_R14, BusIn_R15;
	wire [31:0] BusIn_HI, BusIn_LO, BusIn_Zhigh, BusIn_Zlow, BusIn_PC, BusIn_MDR;
	
	//general purpose 32 bit registers
	register_file GP_reg (
		clear,
		clock,
		GP_addr,
		e_GP,
		BusData,
		BusIn_R0, BusIn_R1, BusIn_R2, BusIn_R3,
		BusIn_R4, BusIn_R5, BusIn_R6, BusIn_R7,
		BusIn_R8, BusIn_R9, BusIn_R10, BusIn_R11,
		BusIn_R12, BusIn_R13, BusIn_R14, BusIn_R15
	);
	
	//instruction registers
	program_counter PC(clear, clock, e_PC, incPC, BusData, BusIn_PC);
	register_32 IR(clear, clock, e_IR, BusData, toControl);
	
	//ALU and related registers
	register_32 Y(clear, clock, e_Y, BusData, ALU_A);
	
	alu ALU(ALU_A, BusData, ALU_op, ALU_C, isZero);
	
	register_64 Z(clear, clock, e_Z, ALU_C, BusIn_Zlow, BusIn_Zhigh);
	register_32 HI(clear, clock, e_HI, BusData, BusIn_HI);
	register_32 LO(clear, clock, e_LO, BusData, BusIn_LO);

	//memory "gateway"
	register_32 MAR(clear, clock, e_MAR, BusData, Maddrout);
	mdr MDR(clear, clock, e_MDR, MDR_read, BusData, Mdatain, BusIn_MDR);
	
	//bus
	bus bus(.data_select(BusDataSelect), .BusMuxIn_R0(BusIn_R0), .BusMuxIn_R1(BusIn_R1), .BusMuxIn_R2(BusIn_R2), .BusMuxIn_R3(BusIn_R3),
		.BusMuxIn_R4(BusIn_R4), .BusMuxIn_R5(BusIn_R5), .BusMuxIn_R6(BusIn_R6), .BusMuxIn_R7(BusIn_R7), .BusMuxIn_R8(BusIn_R8), .BusMuxIn_R9(BusIn_R9),
		.BusMuxIn_R10(BusIn_R10), .BusMuxIn_R11(BusIn_R11), .BusMuxIn_R12(BusIn_R12), .BusMuxIn_R13(BusIn_R13), .BusMuxIn_R14(BusIn_R14),
		.BusMuxIn_R15(BusIn_R15), .BusMuxIn_HI(BusIn_HI), .BusMuxIn_LO(BusIn_LO), .BusMuxIn_Zhigh(BusIn_Zhigh), .BusMuxIn_Zlow(BusIn_Zlow),
		.BusMuxIn_PC(BusIn_PC), .BusMuxIn_MDR(BusIn_MDR), .BusMuxOut(BusData));
	
endmodule
