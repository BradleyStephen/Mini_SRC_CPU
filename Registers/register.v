// 32-bit Register with Load, Clear, and Enable signals
module register (
    input wire clk,        // Clock signal
    input wire reset,      // Asynchronous reset (active high)
    input wire load,       // Load enable signal
    input wire [31:0] d,   // Data input
    output reg [31:0] q    // Data output
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q <= 32'b0; // Clear register to zero on reset
        end
        else if (load) begin
            q <= d;     // Load new data when load is high
        end
    end

endmodule
