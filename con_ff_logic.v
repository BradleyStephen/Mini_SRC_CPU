module con_ff_logic(
	input wire CONin,
	input wire [31:0] Ra_value,
	input wire [3:0] C2,
	output reg CON_out
);

	always @(*) begin
		if (CONin) begin
			case (C2[1:0])  //IR[20..19]
				2'b00: //brzr: branch if zero
					CON_out <= (Ra_value == 32'b0);

				2'b01: //brnz: branch if nonzero
					CON_out <= (Ra_value != 32'b0);

				2'b10: //brpl: branch if positive
					//32-bit signed number, positive MSB = 0 and not zero
					CON_out <= (Ra_value[31] == 1'b0 && Ra_value != 32'b0);

				2'b11: //brmi: branch if negative
					//32-bit signed number, negative MSB = 1
					CON_out <= (Ra_value[31] == 1'b1);
					
				default:
					CON_out <= 1'b0;
			
			endcase
		end
	end

endmodule
