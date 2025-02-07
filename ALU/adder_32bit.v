module adder_32bit(
    input  wire [31:0] A,   // 32-bit input A
    input  wire [31:0] B,   // 32-bit input B
    output wire [31:0] SUM, // 32-bit Sum
    output wire        COUT // Carry out
);
    wire [31:0] c; // Internal carry bits

    // Instantiate 32 full adders in a ripple-carry fashion
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin: adder_gen
            if (i == 0) begin
                // First bit
                full_adder fa_inst (
                    .a(A[i]),
                    .b(B[i]),
                    .cin(1'b0),    // No carry in for the LSB
                    .sum(SUM[i]),
                    .cout(c[i])
                );
            end else begin
                // Subsequent bits
                full_adder fa_inst (
                    .a(A[i]),
                    .b(B[i]),
                    .cin(c[i-1]),
                    .sum(SUM[i]),
                    .cout(c[i])
                );
            end
        end
    endgenerate

    // Final carry out
    assign COUT = c[31];

endmodule
