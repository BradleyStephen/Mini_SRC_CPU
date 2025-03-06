module select_encode(
	input wire [31:0] IR,
	input wire Gra,
	input wire Grb,
	input wire Grc,
	input wire Rin,
	input wire Rout,
	input wire BAout,
	output reg [15:0] Rin,
	output reg [15:0] Rout
	output reg [31:0] C_sign_ext
);

	reg [3:0] Ra, Rb, Rc;
	reg [15:0] decode_out;
	
	always @(posedge clk) begin
		Ra <= IR[26:23];
		Rb <= IR[22:19];
		Rc <= IR[18:15];
	end
	
	and(a, Gra, Ra);
	and(b, Grb, Rb);
	and(c, Grc, Rc);
	or(d, a, b, c);
	
	decode_out[d] <= 1;
	
	
	
	

endmodule
