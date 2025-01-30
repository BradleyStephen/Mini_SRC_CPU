`timescale 1ns/1ps

module datapath_bus_tb;

    // Inputs
    reg clk;
    reg reset;
    reg enable;
    reg [31:0] data_in;     // Data input for register_file and special registers
    reg [4:0] reg_out_select; // Bus selection signal

    // Outputs
    wire [31:0] bus_out;    // Output from the bus

    // Instantiate Top-Level Module
    datapath DUT (
        .clock(clk),
        .clear(reset),
		  .incPC(32'b0),
        .e_r0(e_r0), .e_r1(e_r1), .e_r2(e_r2), .e_r3(e_r3)
        .addr_in(addr_in),
        .addr_out(addr_out),
        .data_in(data_in),
        .reg_out_select(reg_out_select),
        .bus_out(bus_out)
    );

    // Clock Generation (50 MHz)
    initial clk = 0;
    always #10 clk = ~clk;

    // Test Sequence
    initial begin
        $display("Starting Testbench for cpu_top (Bus + Registers)");

        // **Step 1: Reset the System**
        reset = 1; enable = 0; addr_in = 4'b0000; addr_out = 4'b0000; data_in = 32'b0; reg_out_select = 5'b00000;
        #20 reset = 0; // Deactivate reset

        // **Step 2: Write to Registers**
        // Write 0xDEADBEEF to R0
        addr_in = 4'b0000; data_in = 32'hDEADBEEF; enable = 1; #20; enable = 0;

        // Write 0x12345678 to PC
        data_in = 32'h12345678; enable = 1; #20; enable = 0;

        // Write 0xCAFEBABE to IR
        data_in = 32'hCAFEBABE; enable = 1; #20; enable = 0;

        // **Step 3: Select and Verify Bus Outputs**
        // Select R0
        reg_out_select = 5'b00000; addr_out = 4'b0000; #20;
        $display("Bus Output (R0): %h, Expected: DEADBEEF", bus_out);

        // Select PC
        reg_out_select = 5'b10100; #20;
        $display("Bus Output (PC): %h, Expected: 12345678", bus_out);

        // Select IR
        reg_out_select = 5'b10110; #20;
        $display("Bus Output (IR): %h, Expected: CAFEBABE", bus_out);

        // **Step 4: Test Another Register**
        // Write 0xFACECAFE to R1 and read it
        addr_in = 4'b0001; data_in = 32'hFACECAFE; enable = 1; #20; enable = 0;
        reg_out_select = 5'b00001; addr_out = 4'b0001; #20;
        $display("Bus Output (R1): %h, Expected: FACECAFE", bus_out);

        // Finish simulation
        $display("Test Completed");
        $stop;
    end

endmodule
