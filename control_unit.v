`timescale 1ns/10ps

module control_unit (
    // Input signals
    input Clock, Reset, Stop, CON_out,
    input [31:0] IR,

    // Select and encode signals
    output reg Gra, Grb, Grc, e_Rin, e_Rout, BAout,
    
    // Memory signals
    output reg e_MDR, e_MAR, MDR_read, ram_read, ram_write,
    
    // Register enable signals
    output reg e_PC, e_IR, e_Y, e_Z, e_HI, e_LO, e_CON_FF, e_OutPort, e_InPort,
    
    // PC control signals
    output reg incPC,
    
    // ALU operation signals
    output reg [3:0] ALU_op,
    
    // Bus selection signals
    output reg [4:0] BusDataSelect,
    
    // ALU B operand selection
    output reg imm_sel,
    
    // Other control signals
    output reg Clear, Run
);

    // Define states for the control unit
    parameter 
        reset_state = 8'd0,
        fetch0 = 8'd1, fetch1 = 8'd2, fetch2 = 8'd3,
        
        // ld
        ld3 = 8'd4, ld4 = 8'd5, ld5 = 8'd6, ld6 = 8'd7, ld7 = 8'd8,
        
        // ldi
        ldi3 = 8'd9, ldi4 = 8'd10, ldi5 = 8'd11,
        
        // st
        st3 = 8'd12, st4 = 8'd13, st5 = 8'd14, st6 = 8'd15,
        
        // ALU
        add3 = 8'd16, add4 = 8'd17, add5 = 8'd18,
        sub3 = 8'd19, sub4 = 8'd20, sub5 = 8'd21,
        and3 = 8'd22, and4 = 8'd23, and5 = 8'd24,
        or3 = 8'd25, or4 = 8'd26, or5 = 8'd27,
        shl3 = 8'd28, shl4 = 8'd29, shl5 = 8'd30,
        shr3 = 8'd31, shr4 = 8'd32, shr5 = 8'd33,
        shra3 = 8'd34, shra4 = 8'd35, shra5 = 8'd36,
        ror3 = 8'd37, ror4 = 8'd38, ror5 = 8'd39,
        rol3 = 8'd40, rol4 = 8'd41, rol5 = 8'd42,
        mul3 = 8'd43, mul4 = 8'd44, mul5 = 8'd45, mul6 = 8'd46,
        div3 = 8'd47, div4 = 8'd48, div5 = 8'd49, div6 = 8'd50,
        neg3 = 8'd51, neg4 = 8'd52,
        not3 = 8'd53, not4 = 8'd54,
        
        // ALU immediate
        addi3 = 8'd55, addi4 = 8'd56, addi5 = 8'd57,
        andi3 = 8'd58, andi4 = 8'd59, andi5 = 8'd60,
        ori3 = 8'd61, ori4 = 8'd62, ori5 = 8'd63,

        // Branch
        br3 = 8'd64, br4 = 8'd65, br5 = 8'd66, br6 = 8'd67,

        // Jump
        jr3 = 8'd68,
        jal3 = 8'd69, jal4 = 8'd70,

        // Special
        mfhi3 = 8'd71,
        mflo3 = 8'd72,

        // I/O
        in3 = 8'd73,
        out3 = 8'd74,

        // CPU function
        nop3 = 8'd75,
        halt3 = 8'd76;

    // State register
    reg [8:0] present_state = reset_state;

    // opcodes
    parameter 
        LD = 5'b00000,
        LDI = 5'b00001,
        ST = 5'b00010,
        ADD = 5'b00011,
        SUB = 5'b00100,
        AND = 5'b00101,
        OR = 5'b00110,
        ROR = 5'b00111,
        ROL = 5'b01000,
        SHR = 5'b01001,
        SHRA = 5'b01010,
        SHL = 5'b01011,
        ADDI = 5'b01100,
        ANDI = 5'b01101,
        ORI = 5'b01110,
        DIV = 5'b01111,
        MUL = 5'b10000,
        NEG = 5'b10001,
        NOT = 5'b10010,
        BR = 5'b10011,
        JAL = 5'b10100,
        JR = 5'b10101,
        IN = 5'b10110,
        OUT = 5'b10111,
        MFLO = 5'b11000,
        MFHI = 5'b11001,
        NOP = 5'b11010,
        HALT = 5'b11011;

    // ALU op codes
    parameter 
        ALU_AND = 4'b0000,
        ALU_OR = 4'b0001,
        ALU_NOT = 4'b0010,
        ALU_ADD = 4'b0011,
        ALU_SUB = 4'b0100,
        ALU_MUL = 4'b0101,
        ALU_DIV = 4'b0110,
        ALU_SHL = 4'b0111,
        ALU_SHR = 4'b1000,
        ALU_ROL = 4'b1001,
        ALU_ROR = 4'b1010,
        ALU_NEG = 4'b1011,
        ALU_SHRA = 4'b1100;

    // Bus data select values
    parameter
        BUS_R0 = 5'b00000,
        BUS_R1 = 5'b00001,
        BUS_R2 = 5'b00010,
        BUS_R3 = 5'b00011,
        BUS_R4 = 5'b00100,
        BUS_R5 = 5'b00101,
        BUS_R6 = 5'b00110,
        BUS_R7 = 5'b00111,
        BUS_R8 = 5'b01000,
        BUS_R9 = 5'b01001,
        BUS_R10 = 5'b01010,
        BUS_R11 = 5'b01011,
        BUS_R12 = 5'b01100,
        BUS_R13 = 5'b01101,
        BUS_R14 = 5'b01110,
        BUS_R15 = 5'b01111,
        BUS_HI = 5'b10000,
        BUS_LO = 5'b10001,
        BUS_ZHIGH = 5'b10010,
        BUS_ZLOW = 5'b10011,
        BUS_PC = 5'b10100,
        BUS_MDR = 5'b10101,
        BUS_INPORT = 5'b10110,
        BUS_IMM = 5'b10111;

    // Finite state machine
    always @(posedge Clock, posedge Reset) begin
        if (Reset == 1'b1)
            present_state <= reset_state;
        else if (Stop == 1'b1)
            present_state <= halt3;
        else
            case (present_state)
                reset_state: present_state <= fetch0;
                
                // Instruction sequence
                fetch0: present_state <= fetch1;
                fetch1: present_state <= fetch2;
                fetch2: begin
                    case (IR[31:27])
                        LD: present_state <= ld3;
                        LDI: present_state <= ldi3;
                        ST: present_state <= st3;
                        ADD: present_state <= add3;
                        SUB: present_state <= sub3;
                        AND: present_state <= and3;
                        OR: present_state <= or3;
                        SHL: present_state <= shl3;
                        SHR: present_state <= shr3;
                        SHRA: present_state <= shra3;
                        ROR: present_state <= ror3;
                        ROL: present_state <= rol3;
                        ADDI: present_state <= addi3;
                        ANDI: present_state <= andi3;
                        ORI: present_state <= ori3;
                        MUL: present_state <= mul3;
                        DIV: present_state <= div3;
                        NEG: present_state <= neg3;
                        NOT: present_state <= not3;
                        BR: present_state <= br3;
                        JR: present_state <= jr3;
                        JAL: present_state <= jal3;
                        MFHI: present_state <= mfhi3;
                        MFLO: present_state <= mflo3;
                        IN: present_state <= in3;
                        OUT: present_state <= out3;
                        NOP: present_state <= nop3;
                        HALT: present_state <= halt3;
                        default: present_state <= fetch0;
                    endcase
                end
                
                // ld
                ld3: present_state <= ld4;
                ld4: present_state <= ld5;
                ld5: present_state <= ld6;
                ld6: present_state <= ld7;
                ld7: present_state <= fetch0;
                
                // ldi
                ldi3: present_state <= ldi4;
                ldi4: present_state <= ldi5;
                ldi5: present_state <= fetch0;
                
                // st
                st3: present_state <= st4;
                st4: present_state <= st5;
                st5: present_state <= st6;
                st6: present_state <= fetch0;
                
                // ALU
                add3: present_state <= add4;
                add4: present_state <= add5;
                add5: present_state <= fetch0;
                
                sub3: present_state <= sub4;
                sub4: present_state <= sub5;
                sub5: present_state <= fetch0;
                
                and3: present_state <= and4;
                and4: present_state <= and5;
                and5: present_state <= fetch0;
                
                or3: present_state <= or4;
                or4: present_state <= or5;
                or5: present_state <= fetch0;
                
                shl3: present_state <= shl4;
                shl4: present_state <= shl5;
                shl5: present_state <= fetch0;
                
                shr3: present_state <= shr4;
                shr4: present_state <= shr5;
                shr5: present_state <= fetch0;
                
                shra3: present_state <= shra4;
                shra4: present_state <= shra5;
                shra5: present_state <= fetch0;
                
                ror3: present_state <= ror4;
                ror4: present_state <= ror5;
                ror5: present_state <= fetch0;
                
                rol3: present_state <= rol4;
                rol4: present_state <= rol5;
                rol5: present_state <= fetch0;
                
                mul3: present_state <= mul4;
                mul4: present_state <= mul5;
                mul5: present_state <= mul6;
                mul6: present_state <= fetch0;
                
                div3: present_state <= div4;
                div4: present_state <= div5;
                div5: present_state <= div6;
                div6: present_state <= fetch0;
                
                neg3: present_state <= neg4;
                neg4: present_state <= fetch0;
                
                not3: present_state <= not4;
                not4: present_state <= fetch0;
                
                // ALU immediate
                addi3: present_state <= addi4;
                addi4: present_state <= addi5;
                addi5: present_state <= fetch0;
                
                andi3: present_state <= andi4;
                andi4: present_state <= andi5;
                andi5: present_state <= fetch0;
                
                ori3: present_state <= ori4;
                ori4: present_state <= ori5;
                ori5: present_state <= fetch0;
                
                // Branch
                br3: present_state <= br4;
                br4: present_state <= br5;
                br5: present_state <= br6;
                br6: present_state <= fetch0;
                
                // Jump
                jr3: present_state <= fetch0;
                
                jal3: present_state <= jal4;
                jal4: present_state <= fetch0;
                
                // Special
                mfhi3: present_state <= fetch0;
                mflo3: present_state <= fetch0;
                
                // I/O
                in3: present_state <= fetch0;
                out3: present_state <= fetch0;
                
                // CPU function
                nop3: present_state <= fetch0;
                halt3: present_state <= halt3;
                
                default: present_state <= fetch0;
            endcase
    end

    // Control signal instruction decode
    always @(present_state) begin
        // Initialize all signals to 0
        Gra <= 0; Grb <= 0; Grc <= 0; e_Rin <= 0; e_Rout <= 0; BAout <= 0;
        e_MDR <= 0; e_MAR <= 0; MDR_read <= 0; ram_read <= 0; ram_write <= 0;
        e_PC <= 0; e_IR <= 0; e_Y <= 0; e_Z <= 0; e_HI <= 0; e_LO <= 0; e_CON_FF <= 0; e_OutPort <= 0; e_InPort <= 0;
        incPC <= 0;
        ALU_op <= 4'b0000;
        BusDataSelect <= 5'b00000;
        imm_sel <= 0;
        Clear <= 0; Run <= 1;
        
        case (present_state)
            reset_state: begin
                Gra <= 0; Grb <= 0; Grc <= 0; e_Rin <= 0; e_Rout <= 0; BAout <= 0;
                e_MDR <= 0; e_MAR <= 0; MDR_read <= 0; ram_read <= 0; ram_write <= 0;
                e_PC <= 0; e_IR <= 0; e_Y <= 0; e_Z <= 0; e_HI <= 0; e_LO <= 0; e_CON_FF <= 0; e_OutPort <= 0; e_InPort <= 0;
                incPC <= 0;
                ALU_op <= 4'b0000;
                BusDataSelect <= 5'b00000;
                imm_sel <= 0;
                Clear <= 1; Run <= 1;
            end
            
            // Instruction fetch sequence
            fetch0: begin
                BusDataSelect <= BUS_PC;
                e_MAR <= 1;
                incPC <= 1;
                e_Z <= 1;
            end
            
            fetch1: begin
                ram_read <= 1;
                MDR_read <= 1;
                e_MDR <= 1;
            end
            
            fetch2: begin
                BusDataSelect <= BUS_MDR;
                e_IR <= 1;
            end
            
            // ld instruction states (ld Rx, C(Ry))
            ld3: begin
                Grb <= 1;
                BAout <= 1;
                e_Y <= 1;
            end
            
            ld4: begin
                imm_sel <= 1;
                ALU_op <= ALU_ADD;
                e_Z <= 1;
                BusDataSelect <= BUS_IMM;
            end
            
            ld5: begin
                e_MAR <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            ld6: begin
                ram_read <= 1;
                MDR_read <= 1;
                e_MDR <= 1;
            end
            
            ld7: begin
                Gra <= 1;
                e_Rin <= 1;
                BusDataSelect <= BUS_MDR;
            end
            
            // ldi instruction states (ldi Rx, C(Ry))
            ldi3: begin
                Grb <= 1;
                BAout <= 1;
                e_Y <= 1;
            end
            
            ldi4: begin
                BusDataSelect <= BUS_IMM;
                ALU_op <= ALU_ADD;
                imm_sel <= 1;
                e_Z <= 1;
            end
            
            ldi5: begin
                BusDataSelect <= BUS_ZLOW;
                Gra <= 1;
                e_Rin <= 1;
            end
            
            // st instruction states (st C(Ry), Rx)
            st3: begin
                Grb <= 1;
                BAout <= 1;
                e_Y <= 1;
            end
            
            st4: begin
                imm_sel <= 1;
                ALU_op <= ALU_ADD;
                e_Z <= 1;
                BusDataSelect <= BUS_IMM;
            end
            
            st5: begin
                e_MAR <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            st6: begin
                Gra <= 1;
                e_Rout <= 1;
                ram_write <= 1;
                e_MDR <= 1;
            end
            
            // ADD instruction states (add Rx, Ry, Rz)
            add3: begin
                Grb <= 1;
                e_Rout <= 1;
                e_Y <= 1;
            end
            
            add4: begin
                Grc <= 1;
                e_Rout <= 1;
                ALU_op <= ALU_ADD;
                e_Z <= 1;
            end
            
            add5: begin
                Gra <= 1;
                e_Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // SUB instruction states (sub Rx, Ry, Rz)
            sub3: begin
                Grb <= 1;
                e_Rout <= 1;
                e_Y <= 1;
            end
            
            sub4: begin
                Grc <= 1;
                e_Rout <= 1;
                ALU_op <= ALU_SUB;
                e_Z <= 1;
            end
            
            sub5: begin
                Gra <= 1;
                e_Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // AND instruction states (and Rx, Ry, Rz)
            and3: begin
                Grb <= 1;
                e_Rout <= 1;
                e_Y <= 1;
            end
            
            and4: begin
                Grc <= 1;
                e_Rout <= 1;
                ALU_op <= ALU_AND;
                e_Z <= 1;
            end
            
            and5: begin
                Gra <= 1;
                e_Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // OR instruction states (or Rx, Ry, Rz)
            or3: begin
                Grb <= 1;
                e_Rout <= 1;
                e_Y <= 1;
            end
            
            or4: begin
                Grc <= 1;
                e_Rout <= 1;
                ALU_op <= ALU_OR;
                e_Z <= 1;
            end
            
            or5: begin
                Gra <= 1;
                e_Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // SHL instruction states (shl Rx, Ry, Rz)
            shl3: begin
                Grb <= 1;
                e_Rout <= 1;
                e_Y <= 1;
            end
            
            shl4: begin
                Grc <= 1;
                e_Rout <= 1;
                ALU_op <= ALU_SHL;
                e_Z <= 1;
            end
            
            shl5: begin
                Gra <= 1;
                e_Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // SHR instruction states (shr Rx, Ry, Rz)
            shr3: begin
                Grb <= 1;
                e_Rout <= 1;
                e_Y <= 1;
            end
            
            shr4: begin
                Grc <= 1;
                e_Rout <= 1;
                ALU_op <= ALU_SHR;
                e_Z <= 1;
            end
            
            shr5: begin
                Gra <= 1;
                e_Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // SHRA instruction states (shra Rx, Ry, Rz)
            shra3: begin
                Grb <= 1;
                e_Rout <= 1;
                e_Y <= 1;
            end
            
            shra4: begin
                Grc <= 1;
                e_Rout <= 1;
                ALU_op <= ALU_SHRA;
                e_Z <= 1;
            end
            
            shra5: begin
                Gra <= 1;
                e_Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // ROR instruction states (ror Rx, Ry, Rz)
            ror3: begin
                Grb <= 1;
                e_Rout <= 1;
                e_Y <= 1;
            end
            
            ror4: begin
                Grc <= 1;
                e_Rout <= 1;
                ALU_op <= ALU_ROR;
                e_Z <= 1;
            end
            
            ror5: begin
                Gra <= 1;
                e_Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // ROL instruction states (rol Rx, Ry, Rz)
            rol3: begin
                Grb <= 1;
                e_Rout <= 1;
                e_Y <= 1;
            end
            
            rol4: begin
                Grc <= 1;
                e_Rout <= 1;
                ALU_op <= ALU_ROL;
                e_Z <= 1;
            end
            
            rol5: begin
                Gra <= 1;
                e_Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // MUL instruction states (mul Ry, Rz)
            mul3: begin
                Grb <= 1;
                e_Rout <= 1;
                e_Y <= 1;
            end
            
            mul4: begin
                Grc <= 1;
                e_Rout <= 1;
                ALU_op <= ALU_MUL;
                e_Z <= 1;
            end
            
            mul5: begin
                e_HI <= 1;
                e_LO <= 1;
                BusDataSelect <= BUS_ZHIGH;
            end
            
            // DIV instruction states (div Ry, Rz)
            div3: begin
                Grb <= 1;
                e_Rout <= 1;
                e_Y <= 1;
            end
            
            div4: begin
                Grc <= 1;
                e_Rout <= 1;
                ALU_op <= ALU_DIV;
                e_Z <= 1;
            end
            
            div5: begin
                e_HI <= 1;
                e_LO <= 1;
                BusDataSelect <= BUS_ZHIGH;
            end
            
            // NEG instruction states (neg Rx, Ry)
            neg3: begin
                Grb <= 1;
                e_Rout <= 1;
                ALU_op <= ALU_NEG;
                e_Z <= 1;
            end
            
            neg4: begin
                Gra <= 1;
                e_Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // NOT instruction states (not Rx, Ry)
            not3: begin
                Grb <= 1;
                e_Rout <= 1;
                ALU_op <= ALU_NOT;
                e_Z <= 1;
            end
            
            not4: begin
                Gra <= 1;
                e_Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // ADDI instruction states (addi Rx, Ry, C)
            addi3: begin
                Grb <= 1;
                e_Rout <= 1;
                e_Y <= 1;
            end
            
            addi4: begin
                imm_sel <= 1;
                ALU_op <= ALU_ADD;
                e_Z <= 1;
                BusDataSelect <= BUS_IMM;
            end
            
            addi5: begin
                Gra <= 1;
                e_Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // ANDI instruction states (andi Rx, Ry, C)
            andi3: begin
                Grb <= 1;
                e_Rout <= 1;
                e_Y <= 1;
            end
            
            andi4: begin
                imm_sel <= 1;
                ALU_op <= ALU_AND;
                e_Z <= 1;
                BusDataSelect <= BUS_IMM;
            end
            
            andi5: begin
                Gra <= 1;
                e_Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // ORI instruction states (ori Rx, Ry, C)
            ori3: begin
                Grb <= 1;
                e_Rout <= 1;
                e_Y <= 1;
            end
            
            ori4: begin
                imm_sel <= 1;
                ALU_op <= ALU_OR;
                e_Z <= 1;
                BusDataSelect <= BUS_IMM;
            end
            
            ori5: begin
                Gra <= 1;
                e_Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // Branch instruction states (brzr/brnz/brpl/brmi Rx, C)
            br3: begin
                Gra <= 1;
                e_Rout <= 1;
                e_CON_FF <= 1;
            end
            
            br4: begin
                e_Y <= 1;
                BusDataSelect <= BUS_PC;
            end
            
            br5: begin
                imm_sel <= 1;
                ALU_op <= ALU_ADD;
                e_Z <= 1;
                BusDataSelect <= BUS_IMM;
            end
            
            br6: begin
                if (CON_out) begin
                    e_PC <= 1;
                    BusDataSelect <= BUS_ZLOW;
                end
            end
            
            // JR instruction state (jr Rx)
            jr3: begin
                Gra <= 1;
                e_Rout <= 1;
                e_PC <= 1;
            end
            
            // JAL instruction state (jal Rx)
            jal3: begin
                e_Rin <= 1;
                // R15 is the return address register in most RISC architectures
                // For Mini SRC, this might be different (e.g., R8 in your test program)
                // Adjust as necessary based on your architecture
                BusDataSelect <= BUS_PC;
                Gra <= 1;
                e_PC <= 1;
            end
            
            // MFHI instruction state (mfhi Rx)
            mfhi3: begin
                Gra <= 1;
                e_Rin <= 1;
                BusDataSelect <= BUS_HI;
            end
            
            // MFLO instruction state (mflo Rx)
            mflo3: begin
                Gra <= 1;
                e_Rin <= 1;
                BusDataSelect <= BUS_LO;
            end
            
            // IN instruction state (in Rx)
            in3: begin
                Gra <= 1;
                e_Rin <= 1;
                e_InPort <= 1;
                BusDataSelect <= BUS_INPORT;
            end
            
            // OUT instruction state (out Rx)
            out3: begin
                Gra <= 1;
                e_Rout <= 1;
                e_OutPort <= 1;
            end
            
            // NOP instruction state (nop)
            nop3: begin
                // NOP does nothing
            end
            
            // HALT instruction state (halt)
            halt3: begin
                Run <= 0;
            end
            default: ;
        endcase
    end
endmodule