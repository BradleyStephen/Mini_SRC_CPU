`timescale 1ns/1ps
module ram_tb;

  // Declare testbench signals
  reg        clr, clk;
  reg        read, write;
  reg [8:0]  addr;
  reg [31:0] data_in;
  wire [31:0] data_out;
  
  // Instantiate the RAM module (from your ram.v file)
  ram DUT (
    .clr     (clr),
    .clk     (clk),
    .read    (read),
    .write   (write),
    .addr    (addr),
    .data_in (data_in),
    .data_out(data_out)
  );
  
  // Clock generation: 10 ns period (5 ns high, 5 ns low)
  initial begin
    clk = 0;
    repeat (250) begin
	   #5 clk = ~clk;
	 end
  end
  
  // Test sequence
  initial begin
    // Initialize signals and apply reset
    clr = 1;
    read = 0;
    write = 0;
    data_in = 32'h0;
    addr = 9'h0;
    
    #12;           // Wait a little, then release reset
    clr = 0;
    
    // Wait for the RAM to load from the hex file via the $readmemh call in ram.v
    #10;
    
    // --- Test Read from Preloaded Memory ---
    // Read from address 0x54 (should be 0x00000097 as per your hex file)
    addr = 9'h054;
    read = 1;
    #10; // Wait one clock cycle
    read = 0;
    
    #10;
    // Read from address 0xDB (should be 0x00000046 as per your hex file)
    addr = 9'h0DB;
    read = 1;
    #10;
   
    
    // --- Test Write and Read-back ---
    #10;
    // Write a new value (e.g., 0xDEADBEEF) to address 0x100.
    addr = 9'h100;
    data_in = 32'hDEADBEEF;
    write = 1;
    #10;  // Wait one clock cycle for the write to occur
    write = 0;
    
    #10;
    // Read back the value from address 0x100.
    addr = 9'h100;
    read = 1;
    #10;

    
    #50;
    $finish;
  end
  
endmodule
