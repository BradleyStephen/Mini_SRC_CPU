`timescale 1ns/10ps

module control_unit (
    // Select and encode signals
    output reg Gra, Grb, Grc, Rin, Rout, BAout,
    
    // Memory signals
    output reg MDRin, MARin, MDR_read, ram_read, ram_write,
    
    // Register enable signals
    output reg PCin, IRin, Yin, Zin, HIin, LOin, CONin, OutPortIn, InPortOut,
    
    // PC control signals
    output reg IncPC, PCout,
    
    // ALU operation signals
    output reg [3:0] ALU_op,
    
    // Bus selection signals
    output reg [4:0] BusDataSelect,
    
    // ALU B operand selection
    output reg imm_sel,
    
    // Other control signals
    output reg Clear, Run,
    
    // Input signals
    input [31:0] IR,
    input Clock, Reset, Stop, CON_out
);

    // Define states for the control unit
    parameter 
        reset_state = 5'b00000,
        fetch0 = 5'b00001, fetch1 = 5'b00010, fetch2 = 5'b00011,
        
        // ld states
        ld3 = 5'b00100, ld4 = 5'b00101, ld5 = 5'b00110, ld6 = 5'b00111, ld7 = 5'b01000,
        
        // ldi states
        ldi3 = 5'b01001, ldi4 = 5'b01010, ldi5 = 5'b01011,
        
        // st states
        st3 = 5'b01100, st4 = 5'b01101, st5 = 5'b01110, st6 = 5'b01111,
        
        // ALU instruction states
        add3 = 5'b10000, add4 = 5'b10001, add5 = 5'b10010,
        sub3 = 5'b10011, sub4 = 5'b10100, sub5 = 5'b10101,
        and3 = 5'b10110, and4 = 5'b10111, and5 = 5'b11000,
        or3 = 5'b11001, or4 = 5'b11010, or5 = 5'b11011,
        shl3 = 5'b11100, shl4 = 5'b11101, shl5 = 5'b11110,
        shr3 = 5'b11111, shr4 = 5'b00000, shr5 = 5'b00001,
        shra3 = 5'b00010, shra4 = 5'b00011, shra5 = 5'b00100,
        ror3 = 5'b00101, ror4 = 5'b00110, ror5 = 5'b00111,
        rol3 = 5'b01000, rol4 = 5'b01001, rol5 = 5'b01010,
        mul3 = 5'b01011, mul4 = 5'b01100, mul5 = 5'b01101,
        div3 = 5'b01110, div4 = 5'b01111, div5 = 5'b10000,
        neg3 = 5'b10001, neg4 = 5'b10010, neg5 = 5'b10011,
        not3 = 5'b10100, not4 = 5'b10101, not5 = 5'b10110,
        
        // ALU immediate instruction states
        addi3 = 5'b10111, addi4 = 5'b11000, addi5 = 5'b11001,
        andi3 = 5'b11010, andi4 = 5'b11011, andi5 = 5'b11100,
        ori3 = 5'b11101, ori4 = 5'b11110, ori5 = 5'b11111,
        
        // Branch instruction states
        br3 = 5'b00001, br4 = 5'b00010, br5 = 5'b00011, br6 = 5'b00100,
        
        // Jump instruction states
        jr3 = 5'b00101,
        jal3 = 5'b00110,
        
        // Special instruction states
        mfhi3 = 5'b00111,
        mflo3 = 5'b01000,
        
        // I/O instruction states
        in3 = 5'b01001,
        out3 = 5'b01010,
        
        // Miscellaneous instruction states
        nop3 = 5'b01011,
        halt_state = 5'b01100;

    // State register
    reg [4:0] present_state = reset_state;

    // Define opcodes (based on the instruction set)
    parameter 
        LD = 5'b00000,
        LDI = 5'b00001,
        ST = 5'b00010,
        ADD = 5'b00011,
        SUB = 5'b00100,
        AND = 5'b00101,
        OR = 5'b00110,
        SHL = 5'b00111,
        SHR = 5'b01000,
        SHRA = 5'b01001,
        ROR = 5'b01010,
        ROL = 5'b01011,
        ADDI = 5'b01100,
        ANDI = 5'b01101,
        ORI = 5'b01110,
        MUL = 5'b01111,
        DIV = 5'b10000,
        NEG = 5'b10001,
        NOT = 5'b10010,
        BRZR = 5'b10011,
        BRNZ = 5'b10100,
        BRPL = 5'b10101,
        BRMI = 5'b10110,
        JR = 5'b10111,
        JAL = 5'b11000,
        IN = 5'b11001,
        OUT = 5'b11010,
        MFHI = 5'b11011,
        MFLO = 5'b11100,
        NOP = 5'b11101,
        HALT = 5'b11110;

    // ALU op codes (match these with your ALU implementation)
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

    // Bus data select values (match these with your bus implementation)
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
        BUS_IMM = 5'b11000;

    // State transition logic
    always @(posedge Clock, posedge Reset) begin
        if (Reset == 1'b1)
            present_state <= reset_state;
        else if (Stop == 1'b1)
            present_state <= halt_state;
        else
            case (present_state)
                reset_state: present_state <= fetch0;
                
                // Instruction fetch sequence
                fetch0: present_state <= fetch1;
                fetch1: present_state <= fetch2;
                fetch2: begin
                    case (IR[31:27]) // Decode based on opcode
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
                        BRZR, BRNZ, BRPL, BRMI: present_state <= br3;
                        JR: present_state <= jr3;
                        JAL: present_state <= jal3;
                        MFHI: present_state <= mfhi3;
                        MFLO: present_state <= mflo3;
                        IN: present_state <= in3;
                        OUT: present_state <= out3;
                        NOP: present_state <= nop3;
                        HALT: present_state <= halt_state;
                        default: present_state <= fetch0;
                    endcase
                end
                
                // ld instruction states
                ld3: present_state <= ld4;
                ld4: present_state <= ld5;
                ld5: present_state <= ld6;
                ld6: present_state <= ld7;
                ld7: present_state <= fetch0;
                
                // ldi instruction states
                ldi3: present_state <= ldi4;
                ldi4: present_state <= ldi5;
                ldi5: present_state <= fetch0;
                
                // st instruction states
                st3: present_state <= st4;
                st4: present_state <= st5;
                st5: present_state <= st6;
                st6: present_state <= fetch0;
                
                // ALU instruction states
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
                mul5: present_state <= fetch0;
                
                div3: present_state <= div4;
                div4: present_state <= div5;
                div5: present_state <= fetch0;
                
                neg3: present_state <= neg4;
                neg4: present_state <= neg5;
                neg5: present_state <= fetch0;
                
                not3: present_state <= not4;
                not4: present_state <= not5;
                not5: present_state <= fetch0;
                
                // ALU immediate instruction states
                addi3: present_state <= addi4;
                addi4: present_state <= addi5;
                addi5: present_state <= fetch0;
                
                andi3: present_state <= andi4;
                andi4: present_state <= andi5;
                andi5: present_state <= fetch0;
                
                ori3: present_state <= ori4;
                ori4: present_state <= ori5;
                ori5: present_state <= fetch0;
                
                // Branch instruction states
                br3: present_state <= br4;
                br4: present_state <= br5;
                br5: present_state <= br6;
                br6: present_state <= fetch0;
                
                // Jump instruction states
                jr3: present_state <= fetch0;
                jal3: present_state <= fetch0;
                
                // Special instruction states
                mfhi3: present_state <= fetch0;
                mflo3: present_state <= fetch0;
                
                // I/O instruction states
                in3: present_state <= fetch0;
                out3: present_state <= fetch0;
                
                // Miscellaneous instruction states
                nop3: present_state <= fetch0;
                halt_state: present_state <= halt_state;
                
                default: present_state <= fetch0;
            endcase
    end

    // Output logic - Generate control signals for each state
    always @(present_state) begin
        // Initialize all signals to 0
        Gra <= 0; Grb <= 0; Grc <= 0; Rin <= 0; Rout <= 0; BAout <= 0;
        MDRin <= 0; MARin <= 0; MDR_read <= 0; ram_read <= 0; ram_write <= 0;
        PCin <= 0; IRin <= 0; Yin <= 0; Zin <= 0; HIin <= 0; LOin <= 0; CONin <= 0; OutPortIn <= 0; InPortOut <= 0;
        IncPC <= 0; PCout <= 0;
        ALU_op <= 4'b0000;
        BusDataSelect <= 5'b00000;
        imm_sel <= 0;
        Clear <= 0; Run <= 1;
        
        case (present_state)
            reset_state: begin
                Clear <= 1;
                Run <= 0;
            end
            
            // Instruction fetch sequence
            fetch0: begin
                PCout <= 1;
                MARin <= 1;
                IncPC <= 1;
                Zin <= 1;
                BusDataSelect <= BUS_PC;
            end
            
            fetch1: begin
                ram_read <= 1;
                MDR_read <= 1;
                MDRin <= 1;
                Zin <= 0;
                PCin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            fetch2: begin
                IRin <= 1;
                BusDataSelect <= BUS_MDR;
            end
            
            // ld instruction states (ld Rx, C(Ry))
            ld3: begin
                Grb <= 1;
                BAout <= 1;
                Yin <= 1;
            end
            
            ld4: begin
                imm_sel <= 1;
                ALU_op <= ALU_ADD;
                Zin <= 1;
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_IMM;
            end
            
            ld5: begin
                MARin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            ld6: begin
                ram_read <= 1;
                MDR_read <= 1;
                MDRin <= 1;
            end
            
            ld7: begin
                BusDataSelect <= BUS_MDR;
            end
            
            // ldi instruction states (ldi Rx, C(Ry))
            ldi3: begin
                Grb <= 1;
                BAout <= 1;
                Yin <= 1;
            end
            
            ldi4: begin
                imm_sel <= 1;
                ALU_op <= ALU_ADD;
                Zin <= 1;
                BusDataSelect <= BUS_IMM;
            end
            
            ldi5: begin
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // st instruction states (st C(Ry), Rx)
            st3: begin
                Grb <= 1;
                BAout <= 1;
                Yin <= 1;
            end
            
            st4: begin
                imm_sel <= 1;
                ALU_op <= ALU_ADD;
                Zin <= 1;
                BusDataSelect <= BUS_IMM;
            end
            
            st5: begin
                MARin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            st6: begin
                Gra <= 1;
                Rout <= 1;
                ram_write <= 1;
                MDRin <= 1;
            end
            
            // ADD instruction states (add Rx, Ry, Rz)
            add3: begin
                Grb <= 1;
                Rout <= 1;
                Yin <= 1;
            end
            
            add4: begin
                Grc <= 1;
                Rout <= 1;
                ALU_op <= ALU_ADD;
                Zin <= 1;
            end
            
            add5: begin
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // SUB instruction states (sub Rx, Ry, Rz)
            sub3: begin
                Grb <= 1;
                Rout <= 1;
                Yin <= 1;
            end
            
            sub4: begin
                Grc <= 1;
                Rout <= 1;
                ALU_op <= ALU_SUB;
                Zin <= 1;
            end
            
            sub5: begin
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // AND instruction states (and Rx, Ry, Rz)
            and3: begin
                Grb <= 1;
                Rout <= 1;
                Yin <= 1;
            end
            
            and4: begin
                Grc <= 1;
                Rout <= 1;
                ALU_op <= ALU_AND;
                Zin <= 1;
            end
            
            and5: begin
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // OR instruction states (or Rx, Ry, Rz)
            or3: begin
                Grb <= 1;
                Rout <= 1;
                Yin <= 1;
            end
            
            or4: begin
                Grc <= 1;
                Rout <= 1;
                ALU_op <= ALU_OR;
                Zin <= 1;
            end
            
            or5: begin
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // SHL instruction states (shl Rx, Ry, Rz)
            shl3: begin
                Grb <= 1;
                Rout <= 1;
                Yin <= 1;
            end
            
            shl4: begin
                Grc <= 1;
                Rout <= 1;
                ALU_op <= ALU_SHL;
                Zin <= 1;
            end
            
            shl5: begin
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // SHR instruction states (shr Rx, Ry, Rz)
            shr3: begin
                Grb <= 1;
                Rout <= 1;
                Yin <= 1;
            end
            
            shr4: begin
                Grc <= 1;
                Rout <= 1;
                ALU_op <= ALU_SHR;
                Zin <= 1;
            end
            
            shr5: begin
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // SHRA instruction states (shra Rx, Ry, Rz)
            shra3: begin
                Grb <= 1;
                Rout <= 1;
                Yin <= 1;
            end
            
            shra4: begin
                Grc <= 1;
                Rout <= 1;
                ALU_op <= ALU_SHRA;
                Zin <= 1;
            end
            
            shra5: begin
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // ROR instruction states (ror Rx, Ry, Rz)
            ror3: begin
                Grb <= 1;
                Rout <= 1;
                Yin <= 1;
            end
            
            ror4: begin
                Grc <= 1;
                Rout <= 1;
                ALU_op <= ALU_ROR;
                Zin <= 1;
            end
            
            ror5: begin
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // ROL instruction states (rol Rx, Ry, Rz)
            rol3: begin
                Grb <= 1;
                Rout <= 1;
                Yin <= 1;
            end
            
            rol4: begin
                Grc <= 1;
                Rout <= 1;
                ALU_op <= ALU_ROL;
                Zin <= 1;
            end
            
            rol5: begin
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // MUL instruction states (mul Ry, Rz)
            mul3: begin
                Grb <= 1;
                Rout <= 1;
                Yin <= 1;
            end
            
            mul4: begin
                Grc <= 1;
                Rout <= 1;
                ALU_op <= ALU_MUL;
                Zin <= 1;
            end
            
            mul5: begin
                HIin <= 1;
                LOin <= 1;
                BusDataSelect <= BUS_ZHIGH;
            end
            
            // DIV instruction states (div Ry, Rz)
            div3: begin
                Grb <= 1;
                Rout <= 1;
                Yin <= 1;
            end
            
            div4: begin
                Grc <= 1;
                Rout <= 1;
                ALU_op <= ALU_DIV;
                Zin <= 1;
            end
            
            div5: begin
                HIin <= 1;
                LOin <= 1;
                BusDataSelect <= BUS_ZHIGH;
            end
            
            // NEG instruction states (neg Rx, Ry)
            neg3: begin
                Grb <= 1;
                Rout <= 1;
                ALU_op <= ALU_NEG;
                Zin <= 1;
            end
            
            neg4: begin
                // This state may not be needed for NEG, could go straight to neg5
                Zin <= 0;
            end
            
            neg5: begin
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // NOT instruction states (not Rx, Ry)
            not3: begin
                Grb <= 1;
                Rout <= 1;
                ALU_op <= ALU_NOT;
                Zin <= 1;
            end
            
            not4: begin
                // This state may not be needed for NOT, could go straight to not5
                Zin <= 0;
            end
            
            not5: begin
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // ADDI instruction states (addi Rx, Ry, C)
            addi3: begin
                Grb <= 1;
                Rout <= 1;
                Yin <= 1;
            end
            
            addi4: begin
                imm_sel <= 1;
                ALU_op <= ALU_ADD;
                Zin <= 1;
                BusDataSelect <= BUS_IMM;
            end
            
            addi5: begin
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // ANDI instruction states (andi Rx, Ry, C)
            andi3: begin
                Grb <= 1;
                Rout <= 1;
                Yin <= 1;
            end
            
            andi4: begin
                imm_sel <= 1;
                ALU_op <= ALU_AND;
                Zin <= 1;
                BusDataSelect <= BUS_IMM;
            end
            
            andi5: begin
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // ORI instruction states (ori Rx, Ry, C)
            ori3: begin
                Grb <= 1;
                Rout <= 1;
                Yin <= 1;
            end
            
            ori4: begin
                imm_sel <= 1;
                ALU_op <= ALU_OR;
                Zin <= 1;
                BusDataSelect <= BUS_IMM;
            end
            
            ori5: begin
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_ZLOW;
            end
            
            // Branch instruction states (brzr/brnz/brpl/brmi Rx, C)
            br3: begin
                Gra <= 1;
                Rout <= 1;
                CONin <= 1;
            end
            
            br4: begin
                PCout <= 1;
                Yin <= 1;
                BusDataSelect <= BUS_PC;
            end
            
            br5: begin
                imm_sel <= 1;
                ALU_op <= ALU_ADD;
                Zin <= 1;
                BusDataSelect <= BUS_IMM;
            end
            
            br6: begin
                if (CON_out) begin
                    PCin <= 1;
                    BusDataSelect <= BUS_ZLOW;
                end
            end
            
            // JR instruction state (jr Rx)
            jr3: begin
                Gra <= 1;
                Rout <= 1;
                PCin <= 1;
            end
            
            // JAL instruction state (jal Rx)
            jal3: begin
                PCout <= 1;
                Rin <= 1;
                // R15 is the return address register in most RISC architectures
                // For Mini SRC, this might be different (e.g., R8 in your test program)
                // Adjust as necessary based on your architecture
                BusDataSelect <= BUS_PC;
                Gra <= 1;
                PCin <= 1;
            end
            
            // MFHI instruction state (mfhi Rx)
            mfhi3: begin
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_HI;
            end
            
            // MFLO instruction state (mflo Rx)
            mflo3: begin
                Gra <= 1;
                Rin <= 1;
                BusDataSelect <= BUS_LO;
            end
            
            // IN instruction state (in Rx)
            in3: begin
                Gra <= 1;
                Rin <= 1;
                InPortOut <= 1;
                BusDataSelect <= BUS_INPORT;
            end
            
            // OUT instruction state (out Rx)
            out3: begin
                Gra <= 1;
                Rout <= 1;
                OutPortIn <= 1;
            end
            
            // NOP instruction state (nop)
            nop3: begin
                // NOP does nothing
            end
            
            // HALT instruction state (halt)
            halt_state: begin
                Run <= 0;
            end
            default: ;
        endcase
    end
endmodule