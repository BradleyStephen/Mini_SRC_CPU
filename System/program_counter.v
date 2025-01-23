module program_counter(input clr, input clk, input enable, input incPC, output [31:0] D, output [31:0] Q);

	always @(negedge clk) begin
		
		if (clr)
			Q <= 0;
		else if (enable)
			Q <= D;
		else if (incPC)
			Q <= Q + 1;
		end
		
	end

endmodule
