module datapath(
	input wire clear, clock, incPC,

	//register write enable signals
	input wire e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MDR, e_MAR, e_GP, e_OutPort, e_InPort,
    
	input wire [3:0] GP_addr,
    
	input wire [31:0] Mdatain,
	input wire MDR_read,
   
	input wire [3:0] ALU_op,
 
   // data signals
	input wire [4:0] BusDataSelect,

	// select and encode signals
	input wire Gra, Grb, Grc, e_Rin, e_Rout, BAout,
    
	// control signal to select ALU B operand
	// When imm_sel is high, use the immediate constant; when low, use the register value.
	input wire imm_sel
);

	wire [31:0] ALU_A;
	wire [31:0] ALU_B;
	wire [63:0] ALU_C;
	wire isZero;

	wire [31:0] IRout;
	wire [31:0] Maddrout;

	wire [31:0] in_port_data, out_port_data;
	
	// Bus signals for GP registers outputs
	wire [31:0] BusData, BusIn_R0, BusIn_R1, BusIn_R2, BusIn_R3, BusIn_R4, BusIn_R5, BusIn_R6, BusIn_R7;
	wire [31:0] BusIn_R8, BusIn_R9, BusIn_R10, BusIn_R11, BusIn_R12, BusIn_R13, BusIn_R14, BusIn_R15;
	wire [31:0] BusIn_HI, BusIn_LO, BusIn_Zhigh, BusIn_Zlow, BusIn_PC, BusIn_MDR, BusIn_InPort;
	
	
	// Wires for select_encode outputs
	wire [15:0] SE_Rin;
	wire [15:0] SE_Rout;
	wire [31:0] C_sign_ext;
    
	// general purpose 32 bit registers
    register_file GP_reg (
        .clr   (clear),
        .clk   (clock),
		  .BAout (BAout),
        .write (SE_Rin),
        .D     (BusData),
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
	program_counter PC(clear, clock, e_PC, incPC, BusData, BusIn_PC);
	register_32 IR(clear, clock, e_IR, BusData, IRout);

	selec_encode SE_Logic(IRout, Gra, Grb, Grc, e_Rin, e_Rout, BAout, SE_Rin, SE_Rout, C_sign_ext);
	
	// ALU and related registers
	register_32 Y(clear, clock, e_Y, BusData, ALU_A);
    
	// Multiplexer to choose ALU's B operand
	// If imm_sel is high, use immediate constant (C_sign_ext); else, use BusData.
    mux2to1_32 mux_ALU_B (
        .in0   (BusData),
        .in1   (C_sign_ext),
        .sel   (imm_sel),
        .out   (ALU_B)
    );
    
	alu ALU(ALU_A, ALU_B, ALU_C, isZero);

	register_64 Z(clear, clock, e_Z, ALU_C, BusIn_Zlow, BusIn_Zhigh);
	
	register_32 HI(clear, clock, e_HI, BusData, BusIn_HI);
	register_32 LO(clear, clock, e_LO, BusData, BusIn_LO);
    
	// Memory "Gateway"
	register_32 MAR(clear, clock, e_MAR, BusData, Maddrout);
	mdr MDR(clear, clock, e_MDR, MDR_read, BusData, Mdatain, BusIn_MDR);
    
    // Instantiate RAM module. (Make sure ram_read and ram_write are driven from testbench)
    wire ram_read;
    wire ram_write;
    ram RAM (
        .clr   (clear),
        .clk   (clock),
        .read  (ram_read),
        .write (ram_write),
        .addr  (Maddrout[8:0]),
        .data_in (BusData),
        .data_out(Mdatain)
    );
    
    // Condition FF Logic
    wire [3:0] C2_field = IRout[22:19];
    wire CON_enable;
    wire RA_en; // Control signal to capture R[Ra] from the bus
    wire [31:0] Ra_value;
    wire CON_out;
    
    register_32 RA_reg (
        .clr    (clear),
        .clk    (clock),
        .enable (RA_en),
        .D      (BusData),
        .Q      (Ra_value)
    );
    
    con_ff_logic CON (
        .clk     (clock),
        .clr     (clear),
        .CONin   (CON_enable),
        .Ra_value(Ra_value),
        .C2_field(C2_field),
        .CON_out (CON_out)
    );
    
    // I/O Ports

	register_32 out_port(clear, clock, e_OutPort, BusData, out_port_data);
	register_32 in_port(clear, clock, e_InPort, in_port_data, BusIn_InPort);
    
    // Bus Multiplexer instantiation using named mapping
    bus Bus (
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
