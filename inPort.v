module in_port(
    input  wire        clr,       // Asynchronous reset
    input  wire        clk,       // Clock
    input  wire        enable,    // Load enable or strobe from input device
    input  wire [31:0] in_data,   // Data from external input device
    output reg [31:0] Q           // Data to internal bus
);

    always @(posedge clk or posedge clr) begin
        if (clr) begin
            Q <= 32'b0;
        end
        else if (enable) begin
            Q <= in_data;
        end
    end

endmodule
