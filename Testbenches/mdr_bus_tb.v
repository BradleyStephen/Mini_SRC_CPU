`timescale 1ns/1ps

module mdr_bus_tb;

    // Testbench signals
    reg  clk;
    reg  reset;
    reg  load;
    reg  read;             // 0=from bus, 1=from memory
    reg  [3:0]  addr_in;
    reg  [3:0]  addr_out;
    reg  [31:0] data_in;
    reg  [4:0]  reg_out_select;

    wire [31:0] bus_out;
    wire [31:0] mdr_out;

    // Instantiate the CPU top
    cpu_top uut (
        .clk            (clk),
        .reset          (reset),
        .load           (load),
        .addr_in        (addr_in),
        .addr_out       (addr_out),
        .data_in        (data_in),
        .reg_out_select (reg_out_select),
        .read           (read),
        .bus_out        (bus_out),
        .mdr_out        (mdr_out)
    );

    // Clock generation: 50 MHz example => period=20 ns
    initial begin
        clk = 0;
    end

    always #10 clk = ~clk;  // Toggle clk every 10 ns => period = 20 ns

    // Test sequence
    initial begin
        $display("\n=== Starting MDR and Bus Integration Testbench ===");
        $monitor($time, 
                 " | load=%b read=%b data_in=%h bus_out=%h mdr_out=%h",
                  load, read, data_in, bus_out, mdr_out);

        // Initialize
        reset          = 1;
        load           = 0;
        read           = 0;
        addr_in        = 4'b0000;
        addr_out       = 4'b0000;
        data_in        = 32'h00000000;
        reg_out_select = 5'b00000;  // R0 drives the bus initially

        #20;  // Wait for reset
        reset = 0;

        // 1 Write some data into R0 (just to have something in the register file)
        addr_in  = 4'd0;   // Write to R0
        data_in  = 32'hABCD1234;
        load     = 1;      // Load register file
        #20;
        load     = 0;

        // 2 Select R0 onto the bus (to read the data from R0)
        addr_out = 4'd0;
        reg_out_select = 5'b00000; // R0 -> bus
        #20;

        // 3 Now load the MDR from the bus (read=0 => from bus)
        load = 1;   // Reusing the "load" line as MDR's mdr_in
        read = 0;   // from bus
        #20;
        load = 0;
        #10;
        $display("Loaded MDR from bus (R0 contents). Expect MDR=ABCD1234 => mdr_out=%h", mdr_out);

        // 4 Now load from memory (read=1 => from memory). Memory is DEADBEEF
        load = 1;
        read = 1;
        #20;
        load = 0;
        #10;
        $display("Loaded MDR from memory. Expect MDR=DEADBEEF => mdr_out=%h", mdr_out);

        // 5 Check data retention
        #20;
        $display("Data retention in MDR => expect DEADBEEF => mdr_out=%h", mdr_out);

        // 6 Now select MDR output onto bus
        reg_out_select = 5'b10101;  // This chooses BusMuxIn_MDR
        #20;
        $display("Bus driven by MDR => bus_out=%h (expect DEADBEEF)", bus_out);

        // 7 Reset
        reset = 1; #20; reset = 0;
        $display("After reset => mdr_out=%h (expect 00000000)", mdr_out);

        $display("\n=== MDR and Bus Integration Test Completed ===");
        $stop;
    end

endmodule
