`timescale 1ns/10ps
module datapath_tb_ld;

  // Clock and reset signals
  reg clear, clock, incPC;
  
  // Register enable signals for PC, IR, Y, Z, HI, LO, MDR, MAR, GP
  reg e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MDR, e_MAR, e_GP;
  reg [3:0] GP_addr;
  
  // Memory and ALU signals
  reg [31:0] Mdatain;
  reg MDR_read;
  reg [3:0] ALU_op;
  
  // Bus multiplexer control
  reg [4:0] BusDataSelect;
  
  // Control signals for Select Encode (manually driven)
  reg Gra, Grb, Grc;
  reg Rin_en, Rout_en, BAout;
  
  // ALU operand multiplexer control
  // For ld, normally we use the register-sourced operand (imm_sel = 0)
  // Except in T4, where we need to output the constant.
  reg imm_sel;
  
  // I/O signals (not used in ld test)
  reg e_Out, e_IN;
  reg [31:0] ExternalData;
  
  // RAM control signals
  reg ram_read, ram_write;
  
  // For capturing register R[Ra] (not used in ld test)
  reg RA_en;
  reg CON_enable;
  
  // State machine for ld control sequence (T0 to T7)
  parameter T0 = 0, T1 = 1, T2 = 2, T3 = 3, T4 = 4, T5 = 5, T6 = 6, T7 = 7;
  reg [3:0] state;
  
  // Instantiate the datapath (adjust port mapping as needed)
  datapath DUT (
    .clear(clear),
    .clock(clock),
    .incPC(incPC),
    .e_PC(e_PC),
    .e_IR(e_IR),
    .e_Y(e_Y),
    .e_Z(e_Z),
    .e_HI(e_HI),
    .e_LO(e_LO),
    .e_MDR(e_MDR),
    .e_MAR(e_MAR),
    .e_GP(e_GP),
    .GP_addr(GP_addr),
    .Mdatain(Mdatain),
    .MDR_read(MDR_read),
    .ALU_op(ALU_op),
    .BusDataSelect(BusDataSelect),
    .Gra(Gra),
    .Grb(Grb),
    .Grc(Grc),
    .Rin_en(Rin_en),
    .Rout_en(Rout_en),
    .BAout(BAout),
    .imm_sel(imm_sel)
  );
  
  // Clock generation using a repeat loop (50 cycles, adjust as needed)
  initial begin
    clock = 0;
    repeat (50) begin
      #10 clock = ~clock;
      #10 clock = ~clock;
    end
  end
  
  // Initial conditions
  initial begin
    clear       = 1;
    incPC       = 0;
    e_PC = 0; e_IR = 0; e_Y = 0; e_Z = 0; e_HI = 0; e_LO = 0; e_MDR = 0; e_MAR = 0; e_GP = 0;
    GP_addr     = 4'd0;
    Mdatain     = 32'd0;
    MDR_read    = 0;
    ALU_op      = 4'd3;  // ADD operation for effective address calculation
    BusDataSelect = 5'd0;
    Gra         = 0; Grb = 0; Grc = 0;
    Rin_en      = 0; Rout_en = 0; BAout = 0;
    imm_sel     = 0;     // Default: use register operand for ALU's B
    ram_read    = 0; ram_write = 0;
    e_Out       = 0; e_IN = 0;
    ExternalData = 32'd0;
    RA_en       = 0;
    CON_enable  = 0;
    
    state = T0;
    #20 clear = 0;  // Deassert reset after 20 ns
  end
  
  // State transition: advance state on every posedge clock
  always @(posedge clock) begin
    if (state == T7)
      state <= T0;
    else
      state <= state + 1;
  end
  
  // Drive control signals based on the current state
  always @(state) begin
    // Default: deassert all enables and control signals.
    e_PC = 0; e_IR = 0; e_Y = 0; e_Z = 0; e_HI = 0; e_LO = 0; e_MDR = 0; e_MAR = 0; e_GP = 0;
    incPC = 0;
    MDR_read = 0;
    BusDataSelect = 5'd0;
    Gra = 0; Grb = 0; Grc = 0;
    Rin_en = 0; Rout_en = 0; BAout = 0;
    GP_addr = 4'd0;
    Mdatain = 32'd0;
    ram_read = 0; ram_write = 0;
    imm_sel = 0;
    
    case (state)
      // T0: PCout, MARin, IncPC, Zin
      T0: begin
          BusDataSelect = 5'b10100; // Example code for PCout driving MARin
          e_MAR = 1;
          incPC = 1;
          e_Z = 1;
      end
      
      // T1: Zlowout, PCin, Read, MDRin
      T1: begin
          BusDataSelect = 5'b10101; // Example code for MDR input
          ram_read = 1;            // Activate RAM read
          MDR_read = 1;
          e_MDR = 1;
          // Simulate RAM output: memory at address 0x54 holds 0x97
          Mdatain = 32'h00000097;
      end
      
      // T2: MDRout, IRin
      T2: begin
          BusDataSelect = 5'b10101; // Use MDR output to load IR
          e_IR = 1;
      end
      
      // T3: Grb, BAout, Yin
      T3: begin
          BusDataSelect = 5'b00011; // Example code for a register output driving Y input
          Grb = 1;
          BAout = 1;  // Gates R0 to 0 if selected
          e_Y = 1;
      end
      
      // T4: Cout, ADD, Zin (effective address calculation)
      T4: begin
          // For ld, assert imm_sel so that the ALU multiplexer selects the sign-extended constant.
          imm_sel = 1;
          e_Z = 1;
          ALU_op = 4'b0011;  // ADD operation
      end
      
      // T5: Zlowout, MARin (load computed effective address into MAR)
      T5: begin
          BusDataSelect = 5'b10011; // Code for MAR input
          e_MAR = 1;
      end
      
      // T6: Read, MDRin (read memory data into MDR again)
      T6: begin
          BusDataSelect = 5'b10101;
          ram_read = 1;
          MDR_read = 1;
          e_MDR = 1;
          Mdatain = 32'h00000097;  // Simulate RAM output again
      end
      
      // T7: MDRout, Gra, Rin (load register R4 with value from MDR)
      T7: begin
          BusDataSelect = 5'b10101;
          Gra = 1;
          Rin_en = 1;
          e_GP = 1;
          GP_addr = 4'd4;  // Target register R4
      end
      
      default: ;
    endcase
  end
  
  // End simulation after 500 ns
  //initial begin
    //#500 $finish;
  //end
  initial begin
    #500 $stop;
  end


endmodule
