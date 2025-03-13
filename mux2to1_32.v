module mux2to1_32(
    input  wire [31:0] in0,   // register operand (from BusData)
    input  wire [31:0] in1,   // immediate operand (C_sign_ext)
    input  wire        sel,   // select signal: 0 for in0, 1 for in1
    output wire [31:0] out
);
    assign out = sel ? in1 : in0;
endmodule
