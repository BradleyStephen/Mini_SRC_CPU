module program_counter(
	input wire clr,
	input wire clk,
	input wire enable,
	input wire incPC,
	input wire [31:0] D,
	output reg [31:0] Q
);

	always @(negedge clk or posedge clr) begin
		
		if (clr)
			Q <= 32'b0;
		else if (enable)
			Q <= D;
		else if (incPC)
			Q <= Q + 1;
		
	end

endmodule
