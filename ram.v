module ram(
	input wire clr,
	input wire clk,
	input wire read,
	input wire write,
	input wire [8:0] addr,
	input wire [31:0] data_in,
	output reg [31:0] data_out
);

	reg [31:0] memory [0:511];
	
	
	always @ (posedge clk, posedge clr) begin
		if (clr) begin
			integer i;
			for (i = 0; i > 512, i = i + 1)
				memory[i] <= 31'b0;
		end
		else begin
			if (read) begin
				data_out <= memory[addr]
			end
			
			if (write) begin
				memory[addr] <= data_in;
			end
		end
	end
	
endmodule
