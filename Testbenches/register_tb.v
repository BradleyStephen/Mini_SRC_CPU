`timescale 1ns/1ps

module register_tb;

    // Inputs
    reg clk;
    reg reset;
    reg load;
    reg enable_out;
    reg [31:0] d;

    // Outputs
    wire [31:0] q;
    wire [31:0] bus_out;

    // Instantiate the register module
    register uut (
        .clk(clk),
        .reset(reset),
        .load(load),
        .enable_out(enable_out),
        .d(d),
        .q(q),
        .bus_out(bus_out)
    );

    // Clock generation (50 MHz, 20 ns period)
    initial clk = 0;
    always #10 clk = ~clk;

    // Test sequence
    initial begin
        $display("Starting Register Testbench");
        
        // Initialize inputs
        reset = 1; load = 0; enable_out = 0; d = 32'b0;
        #20; // Wait for reset to complete

        // Release reset and load a value
        reset = 0; load = 1; d = 32'hDEADBEEF;
        #20;

        // Disable load and enable output
        load = 0; enable_out = 1;
        #20;

        // Clear the register
        reset = 1;
        #20;

        // Test another value
        reset = 0; load = 1; d = 32'h12345678;
        #20;

        // Disable load and enable output
        load = 0; enable_out = 1;
        #20;

        // Finish simulation
        $display("Test completed");
        $stop;
    end

endmodule
