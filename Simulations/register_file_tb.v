`timescale 1ns/1ps

module register_file_tb;

    // Inputs
    reg clk;
    reg reset;
    reg [3:0] addr_in;   // Address to write
    reg [3:0] addr_out;  // Address to read
    reg load;
    reg enable_out;
    reg [31:0] data_in;

    // Outputs
    wire [31:0] data_out;

    // Instantiate the register file module
    register_file uut (
        .clk(clk),
        .reset(reset),
        .addr_in(addr_in),
        .addr_out(addr_out),
        .load(load),
        .enable_out(enable_out),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation (50 MHz, 20 ns period)
    initial clk = 0;
    always #10 clk = ~clk;

    // Test sequence
    initial begin
        $display("Starting Register File Testbench");

        // Initialize inputs
        reset = 1; load = 0; enable_out = 0; addr_in = 4'b0000; addr_out = 4'b0000; data_in = 32'b0;
        #20; // Wait for reset to complete

        // Release reset
        reset = 0;

        // Test writing to R0
        addr_in = 4'b0000; data_in = 32'hA5A5A5A5; load = 1;
        #20; // Write data
        load = 0;

        // Test reading from R0
        addr_out = 4'b0000; enable_out = 1;
        #20;

        // Test writing to R7
        addr_in = 4'b0111; data_in = 32'h12345678; load = 1;
        #20; // Write data
        load = 0;

        // Test reading from R7
        addr_out = 4'b0111; enable_out = 1;
        #20;

        // Test reset clears all registers
        reset = 1; #20; reset = 0;

        // Test reading after reset (should output 0)
        addr_out = 4'b0000; enable_out = 1;
        #20;
        addr_out = 4'b0111; enable_out = 1;
        #20;

        // Finish simulation
        $display("Register File Test Completed");
        $stop;
    end

endmodule
