module datapath(
	input wire clear, clock, incPC,
	
	//register write enable signals
	input wire e_r0, e_r1, e_r2, e_r3, e_r4, e_r5, e_r6, e_r7, e_r8, e_r9, e_r10, e_r11, e_r12, e_r13, e_r14, e_r15,
	input wire e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MAR,
	
	//bus mux select signals
	input wire s_r0, s_r1, s_r2, s_r3, s_r4, s_r5, s_r6, s_r7, s_r8, s_r9, s_r10, s_r11, s_r12, s_r13, s_r14, s_r15,
	input wire s_PC, s_Z, s_HI, s_LO, s_MDR, s_Zhigh, s_Zlow,
	
	
	//data signals
	wire [31:0] BusData, BusIn_R0, BusIn_R1, BusIn_R2, BusIn_R3, BusIn_R4, BusIn_R5, BusIn_R6, BusIn_R7;
	wire [31:0] BusIn_R8, BusIn_R9, BusIn_R10, BusIn_R11, BusIn_R12, BusIn_R13, BusIn_R14, BusIn_R15;
	wire [31:0] BusIn_HI, BusIn_LO, BusIn_Zhigh, BusIn_Zlow, BusIn_PC, BusIn_MDR;
);
	
	//general purpose 32 bit registers
	register_32 r0(clear, clock, e_r0, BusData, data_to_bus);
	register_32 r1(clear, clock, e_r1, BusData, data_to_bus);
	register_32 r2(clear, clock, e_r2, BusData, data_to_bus);
	register_32 r3(clear, clock, e_r3, BusData, data_to_bus);
	register_32 r4(clear, clock, e_r4, BusData, data_to_bus);
	register_32 r5(clear, clock, e_r5, BusData, data_to_bus);
	register_32 r6(clear, clock, e_r6, BusData, data_to_bus);
	register_32 r7(clear, clock, e_r7, BusData, data_to_bus);
	register_32 r8(clear, clock, e_r8, BusData, data_to_bus);
	register_32 r9(clear, clock, e_r9, BusData, data_to_bus);
	register_32 r10(clear, clock, e_r10, BusData, data_to_bus);
	register_32 r11(clear, clock, e_r11, BusData, data_to_bus);
	register_32 r12(clear, clock, e_r12, BusData, data_to_bus);
	register_32 r13(clear, clock, e_r13, BusData, data_to_bus);
	register_32 r14(clear, clock, e_r14, BusData, data_to_bus);
	register_32 r15(clear, clock, e_r15, BusData, data_to_bus);
	
	//instruction registers
	program_counter PC(clear, clock, e_PC, inc_PC, BusData, data_to_bus);
	register_32 IR(clear, clock, e_IR, BusData, data_to_bus);
	
	//ALU and related registers
	register_32 Y(clear, clock, e_Y, BusData, data_to_bus);	
	register_64 Z(clear, clock, e_Z, data_in, data_out);
	
	register_32 HI(clear, clock, e_HI, BusData, data_to_bus);
	register_32 LO(clear, clock, e_LO, BusData, data_to_bus);

	//memory "gateway"
	register_32 MAR(clear, clock, e_MAR, BusData, data_to_bus);
	register_32 MDR(clear, clock, e_MDR, BusData, data_to_bus);
	
	//bus
	bus bus(.r0out(s_r0), .r1out(s_r1), .r2out(s_r2), .r3out(s_r3), .r4out(s_r4), .r5out(s_r5), .r6out(s_r6), .r7out(s_r7), .r8out(s_r8), .r9out(s_r9),
		.r10out(s_r10), .r11out(s_r11), .r12out(s_r12), .r13out(s_r13), .r14out(s_r14), .r15out(s_r15), .PCout(s_PC), .Zout(s_Z), .HIout(s_HI), .LOout(s_LO),
		.MDRout(s_MDR), .Zhighout(s_Zhigh), .Zlowout(s_Zlow), .BusMuxIn_R0(BusIn_R0), .BusMuxIn_R1(BusIn_R1), .BusMuxIn_R2(BusIn_R2), .BusMuxIn_R3(BusIn_R3),
		.BusMuxIn_R4(BusIn_R4), .BusMuxIn_R5(BusIn_R5), .BusMuxIn_R6(BusIn_R6), .BusMuxIn_R7(BusIn_R7), .BusMuxIn_R8(BusIn_R8), .BusMuxIn_R9(BusIn_R9),
		.BusMuxIn_R10(BusIn_R10), .BusMuxIn_R11(BusIn_R11), .BusMuxIn_R12(BusIn_R12), .BusMuxIn_R13(BusIn_R13), .BusMuxIn_R14(BusIn_R14),
		.BusMuxIn_R15(BusIn_R15), .BusMuxIn_HI(BusIn_HI), .BusMuxIn_LO(BusIn_LO), .BusMuxIn_Zhigh(BusIn_Zhigh), .BusMuxIn_Zlow(BusIn_Zlow),
		.BusMuxIn_PC(BusIn_PC), .BusMuxIn_MDR(BusIn_MDR), .BusMuxOut(BusData));
	
endmodule
