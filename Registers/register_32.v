module register_32 (
    input wire clr,             // Asynchronous reset (active high)
    input wire clk,             // Clock signal
    input wire enable,          // Load enable signal
    input wire [31:0] D,        // Data input
    output reg [31:0] Q         // Data output (stored value)
);

    // Register data storage logic
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            Q <= 32'b0; // Clear register to zero on reset
        end else if (enable) begin
            Q <= D;     // Load new data when load is high
        end
    end

endmodule
