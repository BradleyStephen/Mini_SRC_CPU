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
    integer i;
    
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            // Initialize all memory locations to 0 on reset.
            for (i = 0; i < 512; i = i + 1) begin
                memory[i] <= 32'b0;
            end
            data_out <= 32'b0;
        end else begin
            if (write) begin
                // Write operation takes priority if both are asserted.
                memory[addr] <= data_in;
            end else if (read) begin
                // Read operation: update data_out from the memory at address.
                data_out <= memory[addr];
            end
        end
    end
    
endmodule
