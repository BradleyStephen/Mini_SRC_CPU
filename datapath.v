module datapath(
    input  wire clear,
    input  wire clock,
    input  wire incPC,
    
    // Register write enable signals for PC, IR, Y, Z, HI, LO, MDR, MAR, GP
    input  wire e_PC,
    input  wire e_IR,
    input  wire e_Y,
    input  wire e_Z,
    input  wire e_HI,
    input  wire e_LO,
    input  wire e_MDR,
    input  wire e_MAR,
    input  wire e_GP,
    
    input  wire [3:0] GP_addr,
    
    input  wire [31:0] Mdatain,
    input  wire MDR_read,
    
    input  wire [3:0] ALU_op,
    
    // Data signals for bus multiplexer
    input  wire [4:0] BusDataSelect,
    
    // Control signals for Select Encode (from your control unit)
    input  wire Gra,
    input  wire Grb,
    input  wire Grc,
    input  wire Rin_en,
    input  wire Rout_en,
    input  wire BAout,
    
    // New control signal to select ALU B operand:
    // When imm_sel is high, use the immediate constant; when low, use the register value.
    input  wire imm_sel
);
    // Internal wires
    wire [31:0] ALU_A;
    wire [63:0] ALU_C;
    wire        isZero;
    
    wire [31:0] toControl;
    wire [31:0] Maddrout;
    
    // Bus signals for GP registers outputs
    wire [31:0] BusData;
    wire [31:0] BusIn_R0, BusIn_R1, BusIn_R2, BusIn_R3;
    wire [31:0] BusIn_R4, BusIn_R5, BusIn_R6, BusIn_R7;
    wire [31:0] BusIn_R8, BusIn_R9, BusIn_R10, BusIn_R11;
    wire [31:0] BusIn_R12, BusIn_R13, BusIn_R14, BusIn_R15;
    wire [31:0] BusIn_HI, BusIn_LO, BusIn_Zhigh, BusIn_Zlow, BusIn_PC, BusIn_MDR;
    
    // Wires for select_encode outputs (declare SE_R_in as 16-bit)
    wire [15:0] SE_R_in;
    wire [15:0] SE_R_out;
    wire [31:0] C_sign_ext;
    
    // General Purpose Register File (16 registers)
    register_file GP_reg (
        .clr   (clear),
        .clk   (clock),
        .write_en (SE_R_in),   // Must be 16 bits
        .D     (BusData),
        .BAout (BAout),
        .Q0    (BusIn_R0),
        .Q1    (BusIn_R1),
        .Q2    (BusIn_R2),
        .Q3    (BusIn_R3),
        .Q4    (BusIn_R4),
        .Q5    (BusIn_R5),
        .Q6    (BusIn_R6),
        .Q7    (BusIn_R7),
        .Q8    (BusIn_R8),
        .Q9    (BusIn_R9),
        .Q10   (BusIn_R10),
        .Q11   (BusIn_R11),
        .Q12   (BusIn_R12),
        .Q13   (BusIn_R13),
        .Q14   (BusIn_R14),
        .Q15   (BusIn_R15)
    );
    
    // Instruction Registers
    program_counter PC_inst (
        .clr   (clear),
        .clk   (clock),
        .enable    (e_PC),
        .incPC (incPC),
        .D     (BusData),
        .Q     (BusIn_PC)
    );
    
    register_32 IR_inst (
        .clr    (clear),
        .clk    (clock),
        .enable (e_IR),
        .D      (BusData),
        .Q      (toControl)
    );
    
    // Select Encode Module
    select_encode SE_inst (
        .clk     (clock),
        .IR      (toControl),
        .Gra     (Gra),
        .Grb     (Grb),
        .Grc     (Grc),
        .Rin_en  (Rin_en),
        .Rout_en (Rout_en),
        .BAout   (BAout),
        .R_in    (SE_R_in),   // 16-bit output
        .R_out   (SE_R_out),
        .C_sign_ext (C_sign_ext)
    );
    
    // ALU and related registers
    register_32 Y_inst (
        .clr    (clear),
        .clk    (clock),
        .enable (e_Y),
        .D      (BusData),
        .Q      (ALU_A)
    );
    
    // Multiplexer to choose ALU's B operand:
    // If imm_sel is high, use immediate constant (C_sign_ext); else, use BusData.
    wire [31:0] ALU_B;
    mux2to1_32 mux_ALU_B_inst (
        .in0   (BusData),
        .in1   (C_sign_ext),
        .sel   (imm_sel),
        .out   (ALU_B)
    );
    
    alu ALU_inst (
        .A    (ALU_A),
        .B    (ALU_B),
        .op   (ALU_op),
        .result (ALU_C),
        .zero (isZero)
    );
    
    register_64 Z_inst (
        .clr   (clear),
        .clk   (clock),
        .enable (e_Z),
        .D     (ALU_C),
        .Q_low (BusIn_Zlow),
        .Q_high(BusIn_Zhigh)
    );
    
    register_32 HI_inst (
        .clr    (clear),
        .clk    (clock),
        .enable (e_HI),
        .D      (BusData),
        .Q      (BusIn_HI)
    );
    
    register_32 LO_inst (
        .clr    (clear),
        .clk    (clock),
        .enable (e_LO),
        .D      (BusData),
        .Q      (BusIn_LO)
    );
    
    // Memory "Gateway"
    register_32 MAR_inst (
        .clr    (clear),
        .clk    (clock),
        .enable (e_MAR),
        .D      (BusData),
        .Q      (Maddrout)
    );
    
    // Instantiate RAM module. (Make sure ram_read and ram_write are driven from testbench)
    wire ram_read;
    wire ram_write;
    ram RAM_inst (
        .clr   (clear),
        .clk   (clock),
        .read  (ram_read),
        .write (ram_write),
        .addr  (Maddrout[8:0]),
        .data_in (BusData),
        .data_out(Mdatain)
    );
    
    mdr MDR_inst (
        .clr    (clear),
        .clk    (clock),
        .enable (e_MDR),
        .read   (MDR_read),
        .BusData(BusData),
        .Mdatain(Mdatain),
        .Q      (BusIn_MDR)
    );
    
    // Condition FF Logic
    wire [3:0] C2_field = toControl[22:19];
    wire CON_enable;
    wire RA_en; // Control signal to capture R[Ra] from the bus
    wire [31:0] Ra_value;
    wire CON_out;
    
    register_32 RA_reg_inst (
        .clr    (clear),
        .clk    (clock),
        .enable (RA_en),
        .D      (BusData),
        .Q      (Ra_value)
    );
    
    con_ff_logic CON_inst (
        .clk     (clock),
        .clr     (clear),
        .CONin   (CON_enable),
        .Ra_value(Ra_value),
        .C2_field(C2_field),
        .CON_out (CON_out)
    );
    
    // I/O Ports
    wire e_Out;
    wire e_IN;
    wire [31:0] ExternalData;
    wire [31:0] out_port_data;
    wire [31:0] InPort_out;
    
    out_port OUT_PORT_inst (
        .clr (clear),
        .clk (clock),
        .enable (e_Out),
        .D (BusData),    // Ensure BusData is 32 bits
        .Q (out_port_data)
    );
    
    in_port IN_PORT_inst (
        .clr (clear),
        .clk (clock),
        .enable (e_IN),
        .in_data (ExternalData),
        .Q (InPort_out)
    );
    
    // Bus Multiplexer instantiation using named mapping
    bus Bus_inst (
        .data_select(BusDataSelect),
        .BusMuxIn_R0(BusIn_R0),
        .BusMuxIn_R1(BusIn_R1),
        .BusMuxIn_R2(BusIn_R2),
        .BusMuxIn_R3(BusIn_R3),
        .BusMuxIn_R4(BusIn_R4),
        .BusMuxIn_R5(BusIn_R5),
        .BusMuxIn_R6(BusIn_R6),
        .BusMuxIn_R7(BusIn_R7),
        .BusMuxIn_R8(BusIn_R8),
        .BusMuxIn_R9(BusIn_R9),
        .BusMuxIn_R10(BusIn_R10),
        .BusMuxIn_R11(BusIn_R11),
        .BusMuxIn_R12(BusIn_R12),
        .BusMuxIn_R13(BusIn_R13),
        .BusMuxIn_R14(BusIn_R14),
        .BusMuxIn_R15(BusIn_R15),
        .BusMuxIn_HI(BusIn_HI),
        .BusMuxIn_LO(BusIn_LO),
        .BusMuxIn_Zhigh(BusIn_Zhigh),
        .BusMuxIn_Zlow(BusIn_Zlow),
        .BusMuxIn_PC(BusIn_PC),
        .BusMuxIn_MDR(BusIn_MDR),
        .BusMuxIn_InPort(InPort_out),
        .BusMuxOut(BusData)
    );
    
endmodule
