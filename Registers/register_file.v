//registers R0 to R15
module register_file (
    input wire clr,
    input wire clk,
    input wire [3:0] reg_addr,       // Address of the register to write to
    input wire enable,                // Load enable signal
    input wire [31:0] D,      // Data to write into the selected register
    output wire [31:0] Q0, Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8, Q9, Q10, Q11, Q12, Q13, Q14, Q15    // Data read from the selected register
);

    // 16 registers (R0 to R15)
    reg [31:0] registers [15:0];
    integer i;

    // Write logic
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            // Clear all registers
            for (i = 0; i < 16; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (enable) begin
            registers[reg_addr] <= D; // Write data to the selected register
        end
    end

    // Read logic
	 
	 assign Q0 = registers[0];
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

	 
	 //assign Q = (enable) ? registers[reg_addr] : 32'bz; // Drive data to bus if enabled

endmodule
