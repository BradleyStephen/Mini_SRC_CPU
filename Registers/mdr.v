module mdr(
	input wire clr,
	input wire clk,
	input wire enable,
	input wire read,
	input wire [31:0] BusData,
	input wire [31:0] Mdatain,
	output reg [31:0] Q
);

	always @(posedge clk or posedge clr) begin
        if (clr) begin
            Q <= 32'b0; // Clear register to zero on reset
        end else if (enable) begin
			if (read)
            Q <= Mdatain;
			else
				Q <= BusData;
        end
    end
	
endmodule
