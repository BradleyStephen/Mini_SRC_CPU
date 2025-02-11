module alu(
    input  wire [31:0] A,     // 32-bit operand A
    input  wire [31:0] B,     // 32-bit operand B
    input  wire [3:0]  op,    // operation selector
    output reg  [63:0] result,// 64-bit result (to accommodate multiplication)
    output wire        zero   // zero flag
    
);

    // SHIFT/ROTATE logic
    wire [4:0] shift_amount = B[4:0]; // Use the bottom 5 bits of B as the shift and rotate count
    wire [31:0] sll_out = A << shift_amount; // Logical shift left
    wire [31:0] srl_out = A >> shift_amount; // Logical shift right
    wire [31:0] rol_out = (A << shift_amount) | (A >> (32 - shift_amount)); // Rotate left
    wire [31:0] ror_out = (A >> shift_amount) | (A << (32 - shift_amount)); // Rotate right
    wire [31:0] sra_out = $signed(A) >>> shift_amount; // SHRA - Arithmetic shift right, keeps MSB intact



    // Internal wires for each operation
    wire [31:0] and_out;
    wire [31:0] or_out;
    wire [31:0] not_out;
    wire [31:0] neg_out;
    wire [31:0] add_out;
    wire        add_cout;
    wire [31:0] sub_out;
    wire        sub_borrow;
    wire [63:0] mult_out;
    wire [31:0] div_quot;
    wire [31:0] div_rem;

    // AND
    assign and_out = A & B;

    // OR
    assign or_out  = A | B;

    // NOT (only on A, ignoring B for this operation)
    assign not_out = ~A;

    // NEG (Two's complement)
    assign neg_out = ~A + 1;  

    // ADD
    adder_32bit u_adder(
        .A(A),
        .B(B),
        .SUM(add_out),
        .COUT(add_cout)
    );

    // SUB
    subtractor_32bit u_sub(
        .A(A),
        .B(B),
        .DIFF(sub_out),
        .BORROW(sub_borrow)
    );

    // MULT
    booth_multiplier u_mult(
        .A(A),
        .B(B),
        .PRODUCT(mult_out)
    );

    // DIV
    divider u_div(
        .A(A),
        .B(B),
        .QUOTIENT(div_quot),
        .REMAINDER(div_rem)
    );

    // Multiplex the output based on `op`
    always @(*) begin
        case(op)
            4'b0000: result = {32'b0, and_out};         // AND
            4'b0001: result = {32'b0, or_out};          // OR
            4'b0010: result = {32'b0, not_out};         // NOT
            4'b0011: result = {32'b0, add_out};         // ADD
            4'b0100: result = {32'b0, sub_out};         // SUB
            4'b0101: result = mult_out;                 // MUL (64-bit)
            4'b0110: result = {div_rem, div_quot};      // DIV (remainder:upper, quotient:lower)
        
            // SHIFT/ROTATE ops
            4'b0111: result = {32'b0, sll_out};         // SLL : shift left
            4'b1000: result = {32'b0, srl_out};         // SRL : shift right
            4'b1001: result = {32'b0, rol_out};         // ROL : rotate left
            4'b1010: result = {32'b0, ror_out};         // ROR : rotate right
            4'b1011: result = {32'b0, neg_out};         // NEG : negate 
            4'b1100: result = {32'b0, sra_out};         // SHRA : Shift right artithmetic - used for signed numnbers




        default: result = 64'b0;
    endcase
end

    // Zero flag (1 if the 64-bit result is all zeroes)
    assign zero = (result == 64'b0);

endmodule
