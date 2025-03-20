module select_encode(
   input wire [31:0] IR,          // Instruction Register value
   input wire Gra,         // Control: select field Ra (IR[26:23])
   input wire Grb,         // Control: select field Rb (IR[22:19])
   input wire Grc,         // Control: select field Rc (IR[18:15])
   input wire e_Rin,      // Enable for generating one-hot input enable signals
   input wire e_Rout,     // Enable for generating one-hot output enable signals
   input wire BAout,       // Optional: force zero output if R0 is selected
   output reg [15:0] Rin,        // One-hot enable signals for register input (R0in-R15in)
   output reg [15:0] Rout,       // One-hot enable signals for register output (R0out-R15out)
	output reg [31:0] C_sign_ext   // 32-bit sign-extended constant
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
    
		// Assign Rin value based on reg_sel
      if (e_Rin)
         Rin[reg_sel] = 1'b1;
		else
			Rin = 16'b0;
		
		//Assign Rout value based on reg_sel and BAout
      if (e_Rout)
			Rout[reg_sel] = 1'b1;
        // Optional: if BAout is asserted and R0 is selected, force output enable to 0.
      else
			Rout = 16'b0;
			
		if (BAout && (reg_sel == 4'b0000))
         Rout = 16'b0;

		// Sign-extend a constant.
    // This replicates IR[18] 14 times to form a 32-bit sign-extended value.
		C_sign_ext <= { {14{IR[18]}}, IR[17:0] };
			
	end

endmodule
