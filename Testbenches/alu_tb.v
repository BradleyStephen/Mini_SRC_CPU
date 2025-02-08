`timescale 1ns / 1ps

module alu_tb();

    // Testbench signals
    reg  [31:0] A, B;
    reg  [3:0]  op;            // 4-bit operation select
    wire [63:0] result;        // 64-bit result from ALU
    wire        zero;          // Zero flag from ALU

    // Instantiate the ALU
    alu uut (
        .A(A),
        .B(B),
        .op(op),
        .result(result),
        .zero(zero)
    );

    initial begin
        // Waveform header (optional, for console output)
        // $display(" time |    op   |           A           |           B           |                    result                    | zero");

        // ---------------------------------------------------
        // 1 AND: op = 4'b0000
        A = 32'hA5A5A5A5;
        B = 32'h5A5A5A5A;
        op = 4'b0000; // AND
        #10;  // Wait 10 time units

        // ---------------------------------------------------
        // 2 OR: op = 4'b0001
        A = 32'hA5A5A5A5;
        B = 32'h5A5A5A5A;
        op = 4'b0001; // OR
        #10;

        // ---------------------------------------------------
        // 3 NOT: op = 4'b0010  (NOT applies to A only)
        A = 32'hFFFF_FFFF;
        B = 32'h0000_0000; // Not used
        op = 4'b0010; // NOT
        #10;

        // ---------------------------------------------------
        // 4 ADD: op = 4'b0011
        A = 32'd10;
        B = 32'd5;
        op = 4'b0011; // ADD
        #10;

        // ---------------------------------------------------
        // 5 SUB: op = 4'b0100
        A = 32'd20;
        B = 32'd7;
        op = 4'b0100; // SUB
        #10;

        // ---------------------------------------------------
        // 6 MUL: op = 4'b0101 (64-bit result)
        A = 32'd7;
        B = 32'd6;
        op = 4'b0101; // MUL
        #10;

        // ---------------------------------------------------
        // 7 DIV: op = 4'b0110 (result = { remainder, quotient })
        A = 32'd42;
        B = 32'd6;
        op = 4'b0110; // DIV
        #10;

        // ---------------------------------------------------
        // 8 SLL (Shift Left Logical): op = 4'b0111
        A = 32'h0000_00FF;
        B = 32'd4; 
        op = 4'b0111; // SLL
        #10;

        // ---------------------------------------------------
        // 9 SRL (Shift Right Logical): op = 4'b1000
        A = 32'hF000_0000;
        B = 32'd4;
        op = 4'b1000; // SRL
        #10;

        // ---------------------------------------------------
        // 10 ROL (Rotate Left): op = 4'b1001
        A = 32'h0000_00FF;
        B = 32'd8; 
        op = 4'b1001; // ROL
        #10;

        // ---------------------------------------------------
        // 11 ROR (Rotate Right): op = 4'b1010
        A = 32'hF000_0000;
        B = 32'd4;
        op = 4'b1010; // ROR
        #10;

        // End of simulation
        $stop;
    end

endmodule
