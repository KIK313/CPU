`ifndef ALU
`define ALU

`include "macros.v"

module ALU(
    input wire clk,
    input wire rst,
    input wire rdy,
    
    // communicate with RS
    input wire work_en,
    input wire[3 : 0] rob_id,
    input wire[5 : 0] opcode,
    input wire[31 : 0] rs1,
    input wire[31 : 0] rs2,
    input wire[31 : 0] imm,
    input wire[31 : 0] pc,

    output reg is_ok, 
    output reg[31 : 0] res,
    output reg[5 : 0] ret_rob_id,
    output reg is_jump,
    output reg[31 : 0] jump_pc,
);
    always @(posedge clk) begin
        if (rst) begin
            is_ok <= 1'b0;
        end else if(rdy) begin
            if (work_en) begin
                is_ok <= 1'b1;
                ret_rob_id <= rob_id;
                case(opcode) 
                    `OP_LUI res <= imm;
                    `OP_AUI res <= pc + imm;
                    `OP_JAL res <= pc + 4;
                    `OP_JALR begin
                        res <= pc + 4;
                        is_jump <= 1'b1;
                        jump_pc <= (rs1 + imm) & {31{1'b1}, 1'b0};
                    end
                    `OP_BEQ begin
                        if (rs1 == rs2) begin
                            is_jump <= 1'b1;
                            jump_pc <= pc + imm;
                        end else begin
                            is_jump <= 1'b0;
                            jump_pc <= pc + 4;
                        end
                    end
                    `OP_BNE begin
                        if (rs1 != rs2) begin
                            is_jump <= 1'b1;
                            jump_pc <= pc + imm;
                        end else begin
                            is_jump <= 1'b0;
                            jump_pc <= pc + 4;
                        end
                    end
                    `OP_BLT begin
                        if ($signed(rs1) < $signed(rs2)) begin
                            is_jump <= 1'b1;
                            jump_pc <= pc + imm;
                        end else begin
                            is_jump <= 1'b0;
                            jump_pc <= pc + 4;
                        end                        
                    end
                    `OP_BGE begin
                        if ($signed(rs1) >= $signed(rs2)) begin
                            is_jump <= 1'b1;
                            jump_pc <= pc + imm;
                        end else begin
                            is_jump <= 1'b0;
                            jump_pc <= pc + 4;
                        end                        
                    end
                    `OP_BLTU begin
                        if (rs1 < rs2) begin
                            is_jump <= 1'b1;
                            jump_pc <= pc + imm;
                        end else begin
                            is_jump <= 1'b0;
                            jump_pc <= pc + 4;
                        end
                    end
                    `OP_BGEU begin
                        if (rs1 >= rs2) begin
                            is_jump <= 1'b1;
                            jump_pc <= pc + imm;
                        end else begin
                            is_jump <= 1'b0;
                            jump_pc <= pc + 4;
                        end
                    end
                    `OP_ADDI res <= rs1 + imm;
                    `OP_SLTI res <= $signed(rs1) < $signed(imm);
                    `OP_SLTIU res <= rs1 < imm; 
                    `OP_XORI res <= rs1 ^ imm;
                    `OP_ORI  res <= rs1 | imm;
                    `OP_ANDI res <= rs1 & imm;
                    `OP_SLLI res <= rs1 << imm[5 : 0];
                    `OP_SRLI res <= rs1 >> imm[5 : 0];
                    `OP_SRAI res <= rs1 >>> imm[5 : 0]; 
                    `OP_ADD  res <= rs1 + rs2;
                    `OP_SUB  res <= rs1 - rs2;
                    `OP_SLL  res <= rs1 << rs2[5 : 0];
                    `OP_SLT  res <= $signed(rs1) < $signed(rs2);
                    `OP_SLTU res <= rs1 < rs2;
                    `OP_XOR res <= rs1 ^ rs2;
                    `OP_SRL res <= rs1 >> rs2[5 : 0];
                    `OP_SRA res <= rs1 >>> rs2[5 : 0];
                    `OP_OR  res <= rs1 | rs2;
                    `OP_AND res <= rs1 & rs2;
                endcase                
            end else begin
                is_ok <= 1'b0;
            end
        end
    end
endmodule

`endif