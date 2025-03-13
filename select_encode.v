module select_encode(
    input  wire        clk,         // Clock if you need to register signals (optional here)
    input  wire [31:0] IR,          // Instruction Register value
    input  wire        Gra,         // Control: select field Ra (IR[26:23])
    input  wire        Grb,         // Control: select field Rb (IR[22:19])
    input  wire        Grc,         // Control: select field Rc (IR[18:15])
    input  wire        Rin_en,      // Enable for generating one-hot input enable signals
    input  wire        Rout_en,     // Enable for generating one-hot output enable signals
    input  wire        BAout,       // Optional: force zero output if R0 is selected
    output reg  [15:0] R_in,        // One-hot enable signals for register input (R0in-R15in)
    output reg  [15:0] R_out,       // One-hot enable signals for register output (R0out-R15out)
    output wire [31:0] C_sign_ext   // 32-bit sign-extended constant
);

    // Internal signal to hold the selected 4-bit register index.
    reg [3:0] reg_sel;

    // Select the register field from IR based on control signals.
    // Priority: Gra > Grb > Grc.
    always @(*) begin
        if (Gra)
            reg_sel = IR[26:23];  // Ra field
        else if (Grb)
            reg_sel = IR[22:19];  // Rb field
        else if (Grc)
            reg_sel = IR[18:15];  // Rc field
        else
            reg_sel = 4'b0000;    // Default to register 0
    end

    // Generate one-hot encoded register input enable signals.
    always @(*) begin
        R_in = 16'b0;
        if (Rin_en)
            R_in[reg_sel] = 1'b1;
    end

    // Generate one-hot encoded register output enable signals.
    always @(*) begin
        R_out = 16'b0;
        if (Rout_en)
            R_out[reg_sel] = 1'b1;
        // Optional: if BAout is asserted and R0 is selected, force output enable to 0.
        if (BAout && (reg_sel == 4'b0000))
            R_out = 16'b0;
    end

    // Sign-extend a constant.
    // Assumption: The constant is contained in IR[17:0] with IR[18] as the sign bit.
    // This replicates IR[18] 14 times to form a 32-bit sign-extended value.
    assign C_sign_ext = { {14{IR[18]}}, IR[17:0] };

endmodule
