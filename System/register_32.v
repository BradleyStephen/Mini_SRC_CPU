module register_32(input clr, input clk, input enable, input [31:0] D, output [31:0] Q);
	
	always @(posedge clk) begin
		if(clr)
			Q <= 0;
		else if (enable)
			Q <= D;
		end
	end
	
endmodule;
