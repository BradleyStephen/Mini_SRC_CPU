module datapath_bus_test (
    input wire clk,
    input wire reset,
    input wire load,
    input wire [3:0] addr_in,
    input wire [3:0] addr_out,
    input wire [31:0] data_in,
    input wire [4:0] reg_out_select,
    output wire [31:0] bus_out
);

    // Internal Signals
    wire [31:0] data_out;           // Output from register_file
    wire [31:0] pc_bus_out, ir_bus_out; // Outputs from special registers
    wire [31:0] BusMuxIn_R0, BusMuxIn_R1, BusMuxIn_R2, BusMuxIn_R3;
    wire [31:0] BusMuxIn_R4, BusMuxIn_R5, BusMuxIn_R6, BusMuxIn_R7;
    wire [31:0] BusMuxIn_R8, BusMuxIn_R9, BusMuxIn_R10, BusMuxIn_R11;
    wire [31:0] BusMuxIn_R12, BusMuxIn_R13, BusMuxIn_R14, BusMuxIn_R15;

    // Instantiate Register File
    register_file reg_file (
        .clk(clk),
        .reset(reset),
        .addr_in(addr_in),
        .addr_out(addr_out),
        .load(load),
        .enable_out(1'b1), // Always enable for this example
        .data_in(data_in),
        .data_out(data_out)
    );

    // Generate connections for register_file outputs to BusMuxIn_*
    wire [31:0] reg_file_bus_inputs [15:0]; // Array to hold outputs for R0-R15
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin
            assign reg_file_bus_inputs[i] = (addr_out == i) ? data_out : 32'bz;
        end
    endgenerate

    // Map array to individual BusMuxIn_* signals
    assign BusMuxIn_R0 = reg_file_bus_inputs[0];
    assign BusMuxIn_R1 = reg_file_bus_inputs[1];
    assign BusMuxIn_R2 = reg_file_bus_inputs[2];
    assign BusMuxIn_R3 = reg_file_bus_inputs[3];
    assign BusMuxIn_R4 = reg_file_bus_inputs[4];
    assign BusMuxIn_R5 = reg_file_bus_inputs[5];
    assign BusMuxIn_R6 = reg_file_bus_inputs[6];
    assign BusMuxIn_R7 = reg_file_bus_inputs[7];
    assign BusMuxIn_R8 = reg_file_bus_inputs[8];
    assign BusMuxIn_R9 = reg_file_bus_inputs[9];
    assign BusMuxIn_R10 = reg_file_bus_inputs[10];
    assign BusMuxIn_R11 = reg_file_bus_inputs[11];
    assign BusMuxIn_R12 = reg_file_bus_inputs[12];
    assign BusMuxIn_R13 = reg_file_bus_inputs[13];
    assign BusMuxIn_R14 = reg_file_bus_inputs[14];
    assign BusMuxIn_R15 = reg_file_bus_inputs[15];

    // Instantiate PC Register
    pc_register pc (
        .clk(clk),
        .reset(reset),
        .load(load),
        .enable_out(1'b1), // Always enable for this example
        .d(data_in),
        .q(),
        .bus_out(pc_bus_out)
    );

    // Instantiate IR Register
    ir_register ir (
        .clk(clk),
        .reset(reset),
        .load(load),
        .enable_out(1'b1), // Always enable for this example
        .d(data_in),
        .q(),
        .bus_out(ir_bus_out)
    );

    // Instantiate Bus
    bus data_bus (
        .BusMuxIn_R0(BusMuxIn_R0), .BusMuxIn_R1(BusMuxIn_R1),
        .BusMuxIn_R2(BusMuxIn_R2), .BusMuxIn_R3(BusMuxIn_R3),
        .BusMuxIn_R4(BusMuxIn_R4), .BusMuxIn_R5(BusMuxIn_R5),
        .BusMuxIn_R6(BusMuxIn_R6), .BusMuxIn_R7(BusMuxIn_R7),
        .BusMuxIn_R8(BusMuxIn_R8), .BusMuxIn_R9(BusMuxIn_R9),
        .BusMuxIn_R10(BusMuxIn_R10), .BusMuxIn_R11(BusMuxIn_R11),
        .BusMuxIn_R12(BusMuxIn_R12), .BusMuxIn_R13(BusMuxIn_R13),
        .BusMuxIn_R14(BusMuxIn_R14), .BusMuxIn_R15(BusMuxIn_R15),
        .BusMuxIn_HI(32'b0), .BusMuxIn_LO(32'b0),
        .BusMuxIn_Zhigh(32'b0), .BusMuxIn_Zlow(32'b0),
        .BusMuxIn_PC(pc_bus_out), .BusMuxIn_IR(ir_bus_out),
        .BusMuxIn_MDR(32'b0),
        .reg_out_select(reg_out_select),
        .BusMuxOut(bus_out)
    );

endmodule
