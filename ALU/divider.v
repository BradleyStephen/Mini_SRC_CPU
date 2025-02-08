module divider(
    input  wire [31:0] A,        // Dividend
    input  wire [31:0] B,        // Divisor
    output wire [31:0] QUOTIENT, // 32-bit quotient
    output wire [31:0] REMAINDER // 32-bit remainder
);
    // We are allowed to use / in the division unit
    assign QUOTIENT  = B != 0 ? A / B : 32'd0; 
    assign REMAINDER = B != 0 ? A % B : 32'd0;

endmodule
