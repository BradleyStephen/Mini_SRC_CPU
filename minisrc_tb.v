`timescale 1ns/10ps

module minisrc_tb;
    // Testbench signals
    reg Clock;
    reg Reset;
    reg Stop;
    reg [31:0] in_port_sim;
    reg [31:0] Mdatain;
    
    wire [31:0] IR_out;
    wire [31:0] PC_out;
    wire Run;
    wire Halt;
    wire [31:0] BusData;
    
    // Instantiate the top-level module
    minisrc uut (
        .Clock(Clock),
        .Reset(Reset),
        .Stop(Stop),
        .in_port_sim(in_port_sim),
        .IR_out(IR_out),
        .PC_out(PC_out),
        .Run(Run),
        .Halt(Halt),
        .BusData(BusData)
    );
    
    // Clock generation: 10ns period (adjust as needed)
    initial begin
        Clock = 0;
        repeat (500) begin
			 #10 Clock = ~Clock;
		  end
    end
      
		
    // Test stimulus
    initial begin
        // Initialize inputs
        Reset = 1;
        Stop = 0;
        in_port_sim = 32'h00000000;
        // For initial simulation, you can preload Mdatain with a known instruction word.
        // For example, let's assume we want to simulate a ldi instruction: 
        // You might use a hex value like 32'h42000054 (for "ldi R4, 0x54")
        Mdatain = 32'h42000054;
        
        // Release Reset after some time.
        #20;
        Reset = 0;
        
        // Run for some time (simulate a few clock cycles)
        #100000;
        
        // Optionally, set Stop to 1 (to simulate HALT)
        Stop = 1;
        
        #20;
        $stop;
    end

endmodule
