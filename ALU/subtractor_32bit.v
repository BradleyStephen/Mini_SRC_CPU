module subtractor_32bit(
    input  wire [31:0] A,     // Minuend
    input  wire [31:0] B,     // Subtrahend
    output wire [31:0] DIFF,  // Result of A - B
    output wire        BORROW // Borrow out (if needed)
);
    wire [31:0] B_complement;  // ~B
    wire [31:0] B_twos_comp;   // ~B + 1
    wire        cout;

    // Invert B
    assign B_complement = ~B;

    // Add 1 to get two's complement of B
    //    We can reuse the adder_32bit for B_complement + 1
    wire [31:0] temp_sum;
    wire        temp_cout;

    adder_32bit add_one (
        .A(B_complement),
        .B(32'b1),
        .SUM(temp_sum),
        .COUT(temp_cout)
    );

    assign B_twos_comp = temp_sum;  // final two's complement of B

    //  A + (~B + 1) => A + B_twos_comp
    adder_32bit subtract_by_adding (
        .A(A),
        .B(B_twos_comp),
        .SUM(DIFF),
        .COUT(cout)
    );

    assign BORROW = ~cout;

endmodule
