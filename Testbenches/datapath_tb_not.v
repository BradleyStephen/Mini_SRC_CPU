`timescale 1ns/10ps
module datapath_tb_not;

    reg clear, clock, incPC;
    reg [3:0] GP_addr;
    reg e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MDR, e_MAR, e_GP;
    
    reg [31:0] Mdatain;
    reg MDR_read;
    
    reg [3:0] alu_op;
    
    reg [4:0] BusDataSelect;
    
    parameter Default = 4'b0000, T0 = 4'b0001, T1 = 4'b0010, T2 = 4'b0011, 
              T3 = 4'b0100, T4 = 4'b0101;

    reg [3:0] Present_state = Default;
    
    datapath DUT(
        .clear(clear),
        .clock(clock),
        .incPC(incPC),
        .GP_addr(GP_addr),
        .Mdatain(Mdatain),
        .MDR_read(MDR_read),
        .e_PC(e_PC),
        .e_IR(e_IR),
        .e_Y(e_Y),
        .e_Z(e_Z),
        .e_HI(e_HI),
        .e_LO(e_LO),
        .e_MDR(e_MDR),
        .e_MAR(e_MAR),
        .e_GP(e_GP),
        .ALU_op(alu_op),
        .BusDataSelect(BusDataSelect)
    );

    initial begin
        clock = 0;
        clear = 1;
    end
    
    always #10 begin
        clock = ~clock;
    end
    
    always @(posedge clock) begin // Finite state machine execution on clock rising edge
        case (Present_state)
            Default : Present_state = T0;
            T0 : Present_state = T1;
            T1 : Present_state = T2;
            T2 : Present_state = T3;
            T3 : Present_state = T4;
        endcase
    end
    
    always @(Present_state) begin // Perform actions in each state
        case (Present_state)
            Default: begin
                clear <= 0;
                BusDataSelect = 5'b00000; GP_addr = 4'b0000;
                e_MAR <= 0; e_Z <= 0; e_PC <= 0; e_MDR <= 0; e_IR <= 0; e_Y <= 0; e_GP = 0; e_HI <= 0; e_LO <= 0;
                incPC <= 0; MDR_read <= 0; alu_op <=
