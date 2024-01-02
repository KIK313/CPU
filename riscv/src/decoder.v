`ifndef DECODER 
`define DECODER

`include "macros.v"

module ins_decoder(
    // communicate with ins_fetch
    input wire[31 : 0] ins, 
    output reg[4 : 0] rs1, 
    output reg[4 : 0] rs2,
    output reg[4 : 0] rd,
    output reg[5 : 0] opcode,
    output reg[31 : 0] imm 
);
    wire[6 : 0] op = ins[6 : 0];
    wire[2 : 0] tp = ins[14 : 12]; 
    wire bit = ins[30 : 30];
    always @(*) begin
        opcode = 6'b0;
        rd = 0;
        rs1 = 0;
        rs2 = 0;
        case(op) 
            7'b0110111: begin // LUI
                imm = {ins[31 : 12], 12'b0};    
                rd = ins[11 : 7];
                opcode = `OP_LUI;
            end
            7'b0010111: begin // AUIPC
                imm = {ins[31 : 12], 12'b0};
                rd = ins[11 : 7];
                opcode = `OP_AUI;
            end
            7'b1101111: begin // JAL
                imm = $signed({ins[31 : 31], ins[19 : 12], ins[20 : 20], ins[30 : 21], 1'b0});
                rd = ins[11 : 7];
                opcode = `OP_JAL;
            end
            7'b1100111: begin // JALR
                imm = $signed(ins[31 : 20]);
                rd = ins[11 : 7];
                rs1 = ins[19 : 15];
                opcode = `OP_JALR;
            end
            7'b1100011: begin 
                imm = $signed({ins[31 : 31], ins[7 : 7], ins[30 : 25], ins[11 : 8], 1'b0});
                rs1 = ins[19 : 15];
                rs2 = ins[24 : 20];
                case(tp) 
                    3'b000: opcode = `OP_BEQ;
                    3'b001: opcode = `OP_BNE;
                    3'b100: opcode = `OP_BLT;
                    3'b101: opcode = `OP_BGE;
                    3'b110: opcode = `OP_BLTU;
                    3'b111: opcode = `OP_BGEU;
                endcase 
            end
            7'b0000011: begin
                imm = $signed(ins[31 : 20]);
                rd = ins[11 : 7];
                rs1 = ins[19 : 15];
                case(tp)
                    3'b000: opcode = `OP_LB;
                    3'b001: opcode = `OP_LH;
                    3'b010: opcode = `OP_LW;
                    3'b100: opcode = `OP_LBU;
                    3'b101: opcode = `OP_LHU;
                endcase
            end
            7'b0100011: begin
                imm = $signed({ins[31 : 25], ins[11 : 7]});
                rs1 = ins[19 : 15];
                rs2 = ins[24 : 20];
                case(op)
                    3'b000: opcode = `OP_SB;
                    3'b001: opcode = `OP_SH;
                    3'b010: opcode = `OP_SW;
                endcase
            end
            7'b0010011: begin                        
                rd = ins[11 : 7];
                rs1 = ins[19 : 15];
                case(op)
                    3'b000: begin
                        imm = $signed(ins[31 : 20]);
                        opcode = `OP_ADDI;
                    end  
                    3'b010: begin
                        imm = $signed(ins[31 : 20]);
                        opcode = `OP_SLTI;
                    end
                    3'b011: begin
                        imm = $signed(ins[31 : 20]);
                        opcode = `OP_SLTIU;
                    end
                    3'b100: begin
                        imm = $signed(ins[31 : 20]);
                        opcode = `OP_XORI;
                    end
                    3'b110: begin
                        imm = $signed(ins[31 : 20]);
                        opcode = `OP_ORI;
                    end
                    3'b111: begin
                        imm = $signed(ins[31 : 20]);
                        opcode = `OP_ANDI;
                    end
                    3'b001: begin
                        imm = $signed({27'b0, ins[24 : 20]});
                        opcode = `OP_SLLI;
                    end
                    3'b101: begin
                        imm = $signed({27'b0, ins[24 : 20]});
                        opcode = bit ? `OP_SRAI : `OP_SRLI;
                    end
                endcase
            end
            7'b0110011: begin
                rd = ins[11 : 7];
                rs1 = ins[19 : 15];
                rs2 = ins[24 : 20];
                case(op)
                    3'b000: opcode = bit ? `OP_SUB : `OP_ADD; 
                    3'b001: opcode = `OP_SLL;
                    3'b010: opcode = `OP_SLT;
                    3'b011: opcode = `OP_SLTU;
                    3'b100: opcode = `OP_XOR;
                    3'b101: opcode = bit ? `OP_SRA : `OP_SRL;
                    3'b110: opcode = `OP_OR;
                    3'b111: opcode = `OP_AND;
                endcase
            end
            default: begin
                
            end
        endcase
    end
endmodule

`endif