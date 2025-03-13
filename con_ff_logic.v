module con_ff_logic(
    input  wire        clk,
    input  wire        clr,
    input  wire        CONin,      // Enable signal to update the CON FF
    input  wire [31:0] Ra_value,   // Value in register Ra
    input  wire [3:0]  C2_field,   // IR[22..19], though only lower bits [20..19] matter
    output reg         CON_out     // 1 if condition is met, 0 otherwise
);

    // On every rising edge of clk or clr, update CON_out if CONin is asserted
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            CON_out <= 1'b0;
        end
        else if (CONin) begin
            case (C2_field[1:0])  // We only care about IR[20..19]
                2'b00: // brzr: branch if zero
                    CON_out <= (Ra_value == 32'b0);

                2'b01: // brnz: branch if nonzero
                    CON_out <= (Ra_value != 32'b0);

                2'b10: // brpl: branch if positive
                    // For a 32-bit signed number, "positive" means MSB=0 AND not zero
                    CON_out <= (Ra_value[31] == 1'b0 && Ra_value != 32'b0);

                2'b11: // brmi: branch if negative
                    // For a 32-bit signed number, "negative" means MSB=1
                    CON_out <= (Ra_value[31] == 1'b1);

                default:
                    CON_out <= 1'b0; 
            endcase
        end
    end

endmodule
