module bus(
	input [4:0] data_select,
	input [31:0] BusMuxIn_R0, BusMuxIn_R1, BusMuxIn_R2, BusMuxIn_R3, BusMuxIn_R4, BusMuxIn_R5, BusMuxIn_R6, BusMuxIn_R7,
	input [31:0] BusMuxIn_R8, BusMuxIn_R9, BusMuxIn_R10, BusMuxIn_R11, BusMuxIn_R12, BusMuxIn_R13, BusMuxIn_R14, BusMuxIn_R15,
	input [31:0] BusMuxIn_HI, BusMuxIn_LO, BusMuxIn_Zhigh, BusMuxIn_Zlow, BusMuxIn_PC, BusMuxIn_MDR,
	input [15:0] Rout, e_Rout, BAout,

   input  wire [31:0] BusMuxIn_InPort, // new for inport
   input [31:0] BusMuxIn_Imm,   // new for c sign exnt

	output reg [31:0] BusMuxOut
);

   reg [4:0] select;

		always @(*) begin

         if (e_Rout || BAout) begin
            case (Rout)
               16'b0000000000000001: select <= 5'b00000;
               16'b0000000000000010: select <= 5'b00001;
               16'b0000000000000100: select <= 5'b00010;
               16'b0000000000001000: select <= 5'b00011;
               16'b0000000000010000: select <= 5'b00100;
               16'b0000000000100000: select <= 5'b00101;
               16'b0000000001000000: select <= 5'b00110;
               16'b0000000010000000: select <= 5'b00111;
               16'b0000000100000000: select <= 5'b01000;
               16'b0000001000000000: select <= 5'b01001;
               16'b0000010000000000: select <= 5'b01010;
               16'b0000100000000000: select <= 5'b01011;
               16'b0001000000000000: select <= 5'b01100;
               16'b0010000000000000: select <= 5'b01101;
               16'b0100000000000000: select <= 5'b01110;
               16'b1000000000000000: select <= 5'b01111;
            endcase
         end else
            select <= data_select;

			case (select)				
				5'b00000: BusMuxOut <= BusMuxIn_R0;
            5'b00001: BusMuxOut <= BusMuxIn_R1;
            5'b00010: BusMuxOut <= BusMuxIn_R2;
            5'b00011: BusMuxOut <= BusMuxIn_R3;
            5'b00100: BusMuxOut <= BusMuxIn_R4;
            5'b00101: BusMuxOut <= BusMuxIn_R5;
            5'b00110: BusMuxOut <= BusMuxIn_R6;
            5'b00111: BusMuxOut <= BusMuxIn_R7;
            5'b01000: BusMuxOut <= BusMuxIn_R8;
            5'b01001: BusMuxOut <= BusMuxIn_R9;
            5'b01010: BusMuxOut <= BusMuxIn_R10;
            5'b01011: BusMuxOut <= BusMuxIn_R11;
            5'b01100: BusMuxOut <= BusMuxIn_R12;
            5'b01101: BusMuxOut <= BusMuxIn_R13;
            5'b01110: BusMuxOut <= BusMuxIn_R14;
            5'b01111: BusMuxOut <= BusMuxIn_R15;
				5'b10000: BusMuxOut <= BusMuxIn_HI;
            5'b10001: BusMuxOut <= BusMuxIn_LO;
            5'b10010: BusMuxOut <= BusMuxIn_Zhigh;
            5'b10011: BusMuxOut <= BusMuxIn_Zlow;
            5'b10100: BusMuxOut <= BusMuxIn_PC;
            5'b10101: BusMuxOut <= BusMuxIn_MDR;
            5'b10110: BusMuxOut <= BusMuxIn_InPort;
            5'b11000: BusMuxOut <= BusMuxIn_Imm; // added for c sign extn
            default: BusMuxOut <= 32'b0;
			endcase
		end
	
endmodule
