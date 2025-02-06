`timescale 1ns/10ps
module datapath_tb();
	
	reg clear, clock;
	reg [3:0] register_addr;
	reg e_GP;
	reg e_MDR;
	
	reg [31:0] data_in;
	reg read;
	
	reg [4:0] BusDataSelect;
	
	
	datapath DUT(
		.clear(clear),
		.clock(clock),
		.reg_addr(register_addr),
		.Mdatain(data_in),
		.read(read),
		.e_GP(e_GP),
		.e_MDR(e_MDR),
		.BusDataSelect(BusDataSelect)
	);
	
	initial clock = 0;
   always #10 clock = ~clock;
	
	initial begin
	
		clear = 1; e_GP = 0; read = 1; data_in = 32'h00000000; BusDataSelect = 5'b10101;
		#20 clear = 0;
		
		data_in = 32'hDEADBEEF; e_MDR = 1; #20; e_MDR = 0;
		register_addr = 4'b0000; e_GP = 1; #20; e_GP = 0;
		
		data_in = 32'h12345678; e_MDR = 1; #20; e_MDR = 0;
		register_addr = 4'b0001; e_GP = 1; #20; e_GP = 0;
		
		data_in = 32'hCAFEBABE; e_MDR = 1; #20; e_MDR = 0;
		register_addr = 4'b0010; e_GP = 1; #20; e_GP = 0;
		
		BusDataSelect = 5'b00000; #20; BusDataSelect = 5'b00001; #20; BusDataSelect = 5'b00010;
	
	end
	
endmodule
