module booth_multiplier(
    input  wire [31:0] A,
    input  wire [31:0] B,
    output reg  [63:0] PRODUCT
);
    reg [63:0] accum;
    reg [63:0] multiplicand_ext;
    reg [63:0] multiplier_ext;
    reg [33:0] booth;        // <--- Declare here (outside procedural block)

    integer i;

    always @(*) begin
        // Sign-extend A, B into 64-bit
        multiplicand_ext = {{32{A[31]}}, A};
        multiplier_ext    = {{32{B[31]}}, B};

        accum = 64'd0;

        // Initialize booth with the lower 32 bits of the multiplier plus an extra bit
        booth = { multiplier_ext[31:0], 1'b0 }; // 33 bits total

        // Perform Booth multiplication
        for (i = 0; i < 32; i = i + 1) begin
            case (booth[1:0])
                2'b01: accum = accum + (multiplicand_ext << i);
                2'b10: accum = accum - (multiplicand_ext << i);
                default: /* no-op */;
            endcase
            // Arithmetic right shift the booth value by 1
            booth = { {1{booth[33]}}, booth[33:1] };
        end

        PRODUCT = accum;
    end

endmodule
