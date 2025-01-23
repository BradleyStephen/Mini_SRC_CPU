module register_64(input clr, input clk, input enable, input [63:0] D, output [63:0] Q);

	always @(posedge clk) begin
		if(clr)
			Q <= 0;
		else if (enable)
			Q <= D;
		end
	end

endmodule
