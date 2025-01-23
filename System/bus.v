module bus(
	input R0out, R1out, R2out, R3out, R4out, R5out, R6out, R7out, R8out, R9out, R10out, R11out, R12out, R13out, R14out, R15out,
	input HIout, LOout, Zhighout, Zlowout, PCout, MDRout,
	
	input [31:0] BusMuxIn_R0, BusMuxIn_R1, BusMuxIn_R2, BusMuxIn_R3, BusMuxIn_R4, BusMuxIn_R5, BusMuxIn_R6, BusMuxIn_R7, BusMuxIn_R8, BusMuxIn_R9, BusMuxIn_R10, BusMuxIn_R11, BusMuxIn_R12, BusMuxIn_R13, BusMuxIn_R14, BusMuxIn_R15,
	input [31:0] BusMuxIn_HI, BusMuxIn_LO, BusMuxIn_Zhigh, BusMuxIn_Zlow, BusMuxIn_PC, BusMuxIn_MDR,
	
	output reg [31:0] BusMuxOut
);

		//Thinking about changing input encoder signals to be single signal with binary encoding to determine what data to use
		//instead of individual signal for each register.

		always @(*) begin
			if(R0out) BusMuxOut <= BusMuxIn_R0;
			if(R1out) BusMuxOut <= BusMuxIn_R1;
			if(R2out) BusMuxOut <= BusMuxIn_R2;
			if(R3out) BusMuxOut <= BusMuxIn_R3;
			if(R4out) BusMuxOut <= BusMuxIn_R4;
			if(R5out) BusMuxOut <= BusMuxIn_R5;
			if(R6out) BusMuxOut <= BusMuxIn_R6;
			if(R7out) BusMuxOut <= BusMuxIn_R7;
			if(R8out) BusMuxOut <= BusMuxIn_R8;
			if(R9out) BusMuxOut <= BusMuxIn_R9;
			if(R10out) BusMuxOut <= BusMuxIn_R10;
			if(R11out) BusMuxOut <= BusMuxIn_R11;
			if(R12out) BusMuxOut <= BusMuxIn_R12;
			if(R13out) BusMuxOut <= BusMuxIn_R13;
			if(R14out) BusMuxOut <= BusMuxIn_R14;
			if(R15out) BusMuxOut <= BusMuxIn_R15;
			
			if(HIout) BusMuxOut <= BusMuxIn_HI;
			if(LOout) BusMuxOut <= BusMuxIn_LO;
			if(Zhighout) BusMuxOut <= BusMuxIn_Zhigh;
			if(Zlowout) BusMuxOut <= BusMuxIn_Zlow;
			if(PCout) BusMuxOut <= BusMuxIn_PC;
			if(MDRout) BusMuxOut <= BusMuxIn_MDR;
		end
	
endmodule
