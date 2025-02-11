`timescale 1ns/10ps
module datapath_tb_div;

    reg clear, clock, incPC;
    reg [3:0] GP_addr;
    reg e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MDR, e_MAR, e_GP;
    
    reg [31:0] Mdatain;
    reg MDR_read;
    
    reg [3:0] alu_op;
    
    reg [4:0] BusDataSelect;
    
    parameter Default = 4'b0000, Reg_load1a = 4'b0001, Reg_load1b = 4'b0010, 
              Reg_load2a = 4'b0011, Reg_load2b = 4'b0100, T0 = 4'b0101, 
              T1 = 4'b0110, T2 = 4'b0111, T3 = 4'b1000, T4 = 4'b1001, 
              T5 = 4'b1010, T6 = 4'b1011;
    
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
    
    // Initialize clock and reset
    initial begin
        clock = 0;
        clear = 1;
    end
    
    always #10 begin
        clock = ~clock;
    end
    
    always @(posedge clock) begin // State transitions on clock edge
        case (Present_state)
            Default : Present_state = Reg_load1a;
            Reg_load1a : Present_state = Reg_load1b;
            Reg_load1b : Present_state = Reg_load2a;
            Reg_load2a : Present_state = Reg_load2b;
            Reg_load2b : Present_state = T0;
            T0 : Present_state = T1;
            T1 : Present_state = T2;
            T2 : Present_state = T3;
            T3 : Present_state = T4;
            T4 : Present_state = T5;
            T5 : Present_state = T6;
        endcase
    end
    
    always @(Present_state) begin // Define control signals for each state
        case (Present_state)
            Default: begin
                clear <= 0;
                BusDataSelect = 5'b00000; GP_addr = 4'b0000; // Initialize signals
                e_MAR <= 0; e_Z <= 0; e_PC <= 0; e_MDR <= 0; e_IR <= 0; 
                e_Y <= 0; e_GP = 0; e_HI <= 0; e_LO <= 0;
                incPC <= 0; MDR_read <= 0; alu_op <= 4'b0110; // DIV ALU opcode
                Mdatain <= 32'h00000000;
            end
            
            // Load R2 with a value (e.g., 0x00000006)
            Reg_load1a: begin
                Mdatain <= 32'h00000006;
                MDR_read <= 1; e_MDR <= 1;
                #20 MDR_read <= 0; e_MDR <= 0;
            end
            Reg_load1b: begin
                BusDataSelect <= 5'b10101; GP_addr <= 4'b0010; e_GP <= 1;
                #20 e_GP <= 0; // Initialize R2
            end

            // Load R6 with a value (e.g., 0x00000004)
            Reg_load2a: begin
                Mdatain <= 32'h00000004;
                MDR_read <= 1; e_MDR <= 1;
                #20 MDR_read <= 0; e_MDR <= 0;
            end
            Reg_load2b: begin
                BusDataSelect <= 5'b10101; GP_addr <= 4'b0110; e_GP <= 1;
                #20 e_GP <= 0; // Initialize R6
            end

            // Instruction Fetch
            T0: begin
                BusDataSelect <= 5'b10100; e_MAR <= 1; incPC <= 1; e_Z <= 1;
                #20 e_MAR <= 0; incPC <= 0; e_Z <= 0;
            end
            T1: begin
                BusDataSelect <= 5'b10011; e_PC <= 1; MDR_read <= 1; e_MDR <= 1;
                Mdatain <= 32'hXXXXXXXX; // Replace with actual MUL opcode if needed
                #20 e_PC <= 0; MDR_read <= 0; e_MDR <= 0;
            end
            T2: begin
                BusDataSelect <= 5'b10101; e_IR <= 1;
                #20 e_IR <= 0;
            end

            // Execute MUL operation
            T3: begin
                BusDataSelect <= 5'b00010; e_Y <= 1; // R2out to Y
                #20 e_Y <= 0;
            end
            T4: begin
                BusDataSelect <= 5'b00110; alu_op <= 4'b0110; e_Z <= 1; // R6out, DIV
                #20 e_Z <= 0;
            end
            T5: begin
                BusDataSelect <= 5'b10011; e_LO <= 1; // Zlowout to LO
                #20 e_LO <= 0;
            end
            T6: begin
                BusDataSelect <= 5'b10010; e_HI <= 1; // Zhighout to HI
                #20 e_HI <= 0;
            end
        endcase
    end

endmodule