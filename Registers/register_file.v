//registers R0 to R15
module register_file (
    input wire clk,
    input wire reset,
    input wire [3:0] addr_in,       // Address of the register to write to
    input wire [3:0] addr_out,      // Address of the register to read from
    input wire load,                // Load enable signal
    input wire enable_out,          // Enable output signal
    input wire [31:0] data_in,      // Data to write into the selected register
    output wire [31:0] data_out     // Data read from the selected register
);

    // 16 registers (R0 to R15)
    reg [31:0] registers [15:0];
    integer i;

    // Write logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Clear all registers
            for (i = 0; i < 16; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (load) begin
            registers[addr_in] <= data_in; // Write data to the selected register
        end
    end

    // Read logic
    assign data_out = (enable_out) ? registers[addr_out] : 32'bz; // Drive data to bus if enabled

endmodule
