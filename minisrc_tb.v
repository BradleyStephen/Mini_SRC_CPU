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
        .Run(Run),
        .Halt(Halt),
        .BusData(BusData)
    );
    
    // Clock generation
    initial begin
		Clock = 0;
		Reset = 1;
      Stop = 0;
		#20
		Reset = 0;
	end
	
	always #10 begin
		Clock = ~Clock;
	end


endmodule
