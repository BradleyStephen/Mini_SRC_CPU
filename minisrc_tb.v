`timescale 1ns/10ps
module minisrc_tb;
    reg Clock;
    reg Reset;
    reg Stop;
    reg [31:0] in_port_sim;
    
    // Instantiate the top module.
    minisrc uut (
        .Clock(Clock),
        .Reset(Reset),
        .Stop(Stop),
        .Con_FF(1'b0),
        .in_port_sim(in_port_sim)
    );
    
    // Clock generation
	 initial begin
		Clock = 0;
		repeat (300) begin
			#10 Clock = ~Clock;
		end
	 end
    // Stimulus
    initial begin
        // Initialize inputs
        Reset = 1;
        Stop = 0;
        in_port_sim = 32'h00000000;
        
        // Release reset after 50 ns
        #50;
        Reset = 0;
        
        // Let the simulation run for some time to execute instructions
        #1000;
        
        // Then stop simulation
        Stop = 1;
        #50;
        $finish;
		  end
    
endmodule
