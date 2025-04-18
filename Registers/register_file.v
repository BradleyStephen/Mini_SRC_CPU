module register_file (
	input wire clr,
	input wire clk,
	input wire BAout,
	input wire [15:0] write,
	input wire [31:0] D,
	output wire [31:0] Q0,
	output wire [31:0] Q1,
	output wire [31:0] Q2,
	output wire [31:0] Q3,
	output wire [31:0] Q4,
	output wire [31:0] Q5,
	output wire [31:0] Q6,
	output wire [31:0] Q7,
	output wire [31:0] Q8,
	output wire [31:0] Q9,
	output wire [31:0] Q10,
	output wire [31:0] Q11,
	output wire [31:0] Q12,
	output wire [31:0] Q13,
	output wire [31:0] Q14,
	output wire [31:0] Q15
);

	reg [31:0] registers [15:0];
	integer i;
    
	//write logic 
	always @(posedge clk or posedge clr) begin
		if (clr) begin
			for (i = 0; i < 16; i = i + 1)
				registers[i] <= 32'b0;
		end else begin
			for (i = 0; i < 16; i = i + 1) begin
				if (write[i])
					registers[i] <= D;
			end
		end
	end

	//read logic
    assign Q0 = (BAout) ? 32'b0 : registers[0];
    assign Q1 = registers[1];
    assign Q2 = registers[2];
    assign Q3 = registers[3];
    assign Q4 = registers[4];
    assign Q5 = registers[5];
    assign Q6 = registers[6];
    assign Q7 = registers[7];
    assign Q8 = registers[8];
    assign Q9 = registers[9];
    assign Q10 = registers[10];
    assign Q11 = registers[11];
    assign Q12 = registers[12];
    assign Q13 = registers[13];
    assign Q14 = registers[14];
    assign Q15 = registers[15];

endmodule
