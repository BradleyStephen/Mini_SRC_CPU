`timescale 1ns/1ps

module mdr_tb;

    reg clk;
    reg clr;
    reg mdr_in;
    reg read;
    reg [31:0] bus_mux_out;
    reg [31:0] mdatain;
    wire [31:0] mdr_out;

    // Instantiate MDR module
    mdr uut (
        .clk(clk),
        .clr(clr),
        .mdr_in(mdr_in),
        .read(read),
        .bus_mux_out(bus_mux_out),
        .mdatain(mdatain),
        .mdr_out(mdr_out)
    );

    // Clock Generation (50 MHz)
    initial clk = 0;
    always #10 clk = ~clk;

    // Test Sequence
    initial begin
        $display("Starting MDR Testbench");

        // Reset MDR
        clr = 1; mdr_in = 0; read = 0; bus_mux_out = 32'h00000000; mdatain = 32'h00000000; #20;
        clr = 0;

        // Load from Bus (bus_mux_out)
        bus_mux_out = 32'hA5A5A5A5; read = 0; mdr_in = 1; #20; mdr_in = 0;
        $display("MDR Output (From Bus): %h, Expected: A5A5A5A5", mdr_out);

        // Load from Memory (mdatain)
        mdatain = 32'hDEADBEEF; read = 1; mdr_in = 1; #20; mdr_in = 0;
        $display("MDR Output (From Memory): %h, Expected: DEADBEEF", mdr_out);

        // Clear MDR
        clr = 1; #20; clr = 0;
        $display("MDR Output After Clear: %h, Expected: 00000000", mdr_out);

        $display("MDR Test Completed");
        $stop;
    end
endmodule
