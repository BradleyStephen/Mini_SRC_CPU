module out_port(
    input  wire        clr,      // Asynchronous reset
    input  wire        clk,      // Clock
    input  wire        enable,   // Load enable from control or testbench
    input  wire [31:0] D,        // Data input (from internal bus)
    output reg [31:0] Q          // Data output to external device
);

    always @(posedge clk or posedge clr) begin
        if (clr) begin
            Q <= 32'b0;
        end
        else if (enable) begin
            Q <= D;
        end
    end

endmodule
