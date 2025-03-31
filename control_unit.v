`timescale 1ns/10ps
module control_unit (
    // Control signals (all outputs) that drive the datapath:
    output reg e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_MDR, e_MAR, e_GP, e_OutPort, e_InPort,
    output reg e_RA, e_CON_FF,
    output reg ram_read, ram_write,
    output reg MDR_read,
    output reg [3:0] ALU_op,
    output reg [4:0] BusDataSelect,
    output reg imm_sel,
    output reg Gra, Grb, Grc,  // These may be used to drive the select_encode module
    // Inputs:
    input [31:0] IR,       // Instruction Register (from datapath)
    input Clock, Reset, Stop, Con_FF
);

    // Define FSM states. (For illustration, we implement only a few states.)
    localparam RESET_STATE = 4'd0,
               FETCH_T0    = 4'd1,
               FETCH_T1    = 4'd2,
               FETCH_T2    = 4'd3,
               EXECUTE     = 4'd4,
               HALT        = 4'd15;
               
    reg [3:0] state, next_state;
    
    // Sequential: update current state on Clock or reset.
    always @(posedge Clock or posedge Reset) begin
        if (Reset)
            state <= RESET_STATE;
        else
            state <= next_state;
    end
    
    // Combinational: next state and output logic.
    always @(*) begin
        // Default de-assert (0) all control signals
        e_PC = 0; e_IR = 0; e_Y = 0; e_Z = 0; e_HI = 0; e_LO = 0;
        e_MDR = 0; e_MAR = 0; e_GP = 0; e_OutPort = 0; e_InPort = 0;
        e_RA = 0; e_CON_FF = 0;
        ram_read = 0; ram_write = 0; MDR_read = 0;
        ALU_op = 4'b0000;
        BusDataSelect = 5'b00000;
        imm_sel = 0;
        Gra = 0; Grb = 0; Grc = 0;
        next_state = state; // Default hold state
        
        case (state)
            RESET_STATE: begin
                // In reset state, the datapath registers are cleared.
                next_state = FETCH_T0;
            end
            
            FETCH_T0: begin
                // T0: PCout, MARin, IncPC, Zin
                // (BusDataSelect=10100 corresponds to PCout)
                BusDataSelect = 5'b10100;
                e_MAR = 1;
                e_Z = 1;
                // Assert incPC signal by setting a dedicated bit (assume it's tied to e_PC or incPC input)
                // For example purposes, we assume e_PC is used for latching PC input.
                // Also assert a flag that tells the datapath to increment the PC.
                // (You may need to add an "incPC" signal if not already present.)
                // Here we assume the testbench drives incPC separately.
                next_state = FETCH_T1;
            end
            
            FETCH_T1: begin
                // T1: Zlowout, PCin, initiate memory read.
                BusDataSelect = 5'b10011; // Code for Zlowout
                e_PC = 1;                // PCin enabled
                ram_read = 1;            // Start memory read
                next_state = FETCH_T2;
            end
            
            FETCH_T2: begin
                // T2: MDRout -> IR.
                BusDataSelect = 5'b10101; // Code for MDRout
                e_IR = 1;                 // Load IR with MDR
                next_state = EXECUTE;
            end
            
            EXECUTE: begin
                // For this example, we simply decode the IR opcode.
                // In a complete design, you would have many states to generate signals for each instruction.
                case (IR[31:27])
                    5'b00000: begin // Example: assume 00000 is nop
                        next_state = FETCH_T0;
                    end
                    5'b11111: begin // Example: assume 11111 is halt
                        next_state = HALT;
                    end
                    default: begin
                        // For any other instruction, simply move to the next fetch cycle.
                        next_state = FETCH_T0;
                    end
                endcase
            end
            
            HALT: begin
                // For halt, do nothing (all control signals 0) and remain in halt state.
                next_state = HALT;
            end
            
            default: next_state = RESET_STATE;
        endcase
    end

endmodule
