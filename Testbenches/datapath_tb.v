`timescale 1ns/10ps
module datapath_tb();
	
	reg clear, clock, incPC;
	reg [3:0] GP_addr;
	reg e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MDR, e_MAR, e_GP;
	
	reg [31:0] data_in;
	reg MDR_read;
	
	reg [3:0] alu_op;
	
	reg [4:0] BusDataSelect;
	
	
	datapath DUT(
		.clear(clear),
		.clock(clock),
		.incPC(incPC),
		.GP_addr(GP_addr),
		.Mdatain(data_in),
		.MDR_read(MDR_read),
		.e_PC(e_PC),
		.e_IR(e_IR),
		.e_Y(e_Y),
		.e_Z(e_Z),
		.e_HI(e_HI),
		.e_LO(e_LO),
		.e_MDR(e_MDR),
		.e_MAR(e_MAR),
		.e_GP(e_GP),
		.ALU_op(alu_op),
		.BusDataSelect(BusDataSelect)
	);
	
	initial clock = 0;
   always #10 clock = ~clock;
	
	initial begin
	
		e_PC = 0; e_IR = 0; e_Y = 0; e_Z = 0; e_HI = 0; e_LO = 0; e_MDR = 0; e_MAR = 0; e_GP = 0;
		clear = 1; MDR_read = 1; data_in = 32'h00000000; BusDataSelect = 5'b10101; alu_op = 4'b0001;
		GP_addr = 4'b0000; incPC = 0;
		#20 clear = 0;
		
		data_in = 32'hAAAAAAAA; e_MDR = 1; #20; e_MDR = 0;
		GP_addr = 4'b0000; e_GP = 1; #20; e_GP = 0;
		
		data_in = 32'h55555555; e_MDR = 1; #20; e_MDR = 0;
		GP_addr = 4'b0001; e_GP = 1; #20; e_GP = 0;
		
		data_in = 32'hCAFEBABE; e_MDR = 1; #20; e_MDR = 0;
		GP_addr = 4'b0010; e_GP = 1; #20; e_GP = 0;
		
		BusDataSelect = 5'b00000; e_Y = 1; #20; e_Y = 0;
		BusDataSelect = 5'b00001; e_Z = 1; #20; e_Z = 0;
		BusDataSelect = 5'b10010; e_HI = 1; #20; e_HI = 0;
		BusDataSelect = 5'b10011; e_LO = 1; #20; e_LO = 0;
	
	end
	
endmodule
