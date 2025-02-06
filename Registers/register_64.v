module register_64 (
    input wire clr,             // Asynchronous reset (active high)
    input wire clk,             // Clock signal
    input wire enable,          // Load enable signal
    input wire [63:0] D,        // Data input
    output reg [31:0] Q_low,     // Data output low 32 bits
	 output reg [63:32] Q_high     // Data output high 32 bits (stored value)
);

    // Register data storage logic
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            Q_low <= 16'b0; // Clear register to zero on reset
				Q_high <= 16'b0;
        end else if (enable) begin
            Q_low <= D[31:0];     // Load new data when load is high
				Q_high <= D[63:32];
        end
    end

endmodule
