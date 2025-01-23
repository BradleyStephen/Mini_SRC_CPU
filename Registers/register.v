module register (
    input wire clk,             // Clock signal
    input wire reset,           // Asynchronous reset (active high)
    input wire load,            // Load enable signal
    input wire enable_out,      // Enable output signal for the bus
    input wire [31:0] d,        // Data input
    output reg [31:0] q,        // Data output (stored value)
    output reg [31:0] bus_out   // Data driven to the bus
);

    // Register data storage logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q <= 32'b0; // Clear register to zero on reset
        end else if (load) begin
            q <= d;     // Load new data when load is high
        end
    end

    // Output to the bus logic
    always @(*) begin
        if (enable_out) begin
            bus_out = q; // Drive register value to the bus
        end else begin
            bus_out = 32'bz; // High-impedance state when not enabled
        end
    end

endmodule
