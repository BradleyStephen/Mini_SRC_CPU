module divider (
    input  wire [31:0] A,        // Dividend
    input  wire [31:0] B,        // Divisor
    output reg  [31:0] QUOTIENT, // 32-bit quotient
    output reg  [31:0] REMAINDER // 32-bit remainder
);
    
    reg [31:0] R; // Remainder register
    reg [31:0] Q; // Quotient register
    reg [31:0] M; // Divisor register
    integer i;
    
    always @(*) begin
        if (B == 0) begin
            QUOTIENT  = 32'd0;
            REMAINDER = 32'd0;
        end else begin
            // Initialize registers
            R = 32'd0;
            Q = A;
            M = B;
            
            // Perform Non-Restoring Division for 32 iterations
            for (i = 0; i < 32; i = i + 1) begin
                R = {R[30:0], Q[31]}; // Left shift (R,Q) pair
                Q = {Q[30:0], 1'b0};
                
                // Subtract divisor
                if (R[31] == 0)
                    R = R - M;
                else
                    R = R + M;
                
                // Determine next bit of quotient
                if (R[31] == 0)
                    Q[0] = 1;
                else
                    Q[0] = 0;
            end
            
            // Final correction step if R is negative
            if (R[31] == 1) begin
                R = R + M;
            end
            
            // Assign outputs
            QUOTIENT  = Q;
            REMAINDER = R;
        end
    end
endmodule
