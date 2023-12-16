`ifndef insFetch
`define insFetch

`include "decoder.v"
`include "macros.v"

module insFetch(
    input wire clk,
    input wire rst,
    input wire rdy,

    // communicate with insCache
    input wire hit,
    input wire[31 : 0] ins,
    output wire[31 : 0] addr_to_icache,
    
    // communicate with dispatcher 
    output reg issue_en,
    output reg[31 : 0] once_pc, 
    output reg[5 : 0] opcode,
    output reg rd,
    output reg[4 : 0] rs1,
    output reg[4 : 0] rs2,
    output reg[31 : 0] imm,
    output reg is_br,

    // communicate with rs,rob,lsb
    input wire rs_full,
    input wire rob_full,
    input wire lsb_full,

    // communicate with ROB about branch
    input wire clear,
    input wire[31 : 0] new_pc,

    // rob pre_bits
    input wire upt_en,
    input wire[4 : 0] pre_id,
    input wire is_jump
);
    reg[31 : 0] pc; 
    reg[1 : 0] pre_bits[31 : 0]; // pc 6 -> 2
    integer i;

    wire[5 : 0] opcode_from_id;
    wire[4 : 0] rd_from_id;
    wire[4 : 0] rs1_from_id;
    wire[4 : 0] rs2_from_id;
    wire[31 : 0] imm_from_id;

    assign addr_to_icache = pc;
    ins_decoder ID( 
        .ins(ins),
        .rs1(rs1_from_id),
        .rs2(rs2_from_id),
        .rd(rd_from_id),
        .opcode(opcode_from_id),
        .imm(imm_from_id)
    );
    always@ (posedge clk) begin
        if (rst) begin
            pc <= 32'b0;
            issue_en <= 1'b0;
            for (i = 0; i < 32; i = i + 1) pre_bits[i] <= 2'b10; 
        end else if (rdy) begin
            if (clear) begin
                pc <= new_pc;
                issue_en <= 1'b0;
            end else begin
                if (hit && (!rs_full) && (!rob_full) && (!lsb_full)) begin
                    issue_en <= 1'b1;
                    opcode <= opcode_from_id;
                    rd <= rd_from_id;
                    rs1 <= rs1_from_id;
                    rs2 <= rs2_from_id;
                    imm <= imm_from_id;
                    once_pc <= pc;
                    
                    if (opcode_from_id == `JAL) begin 
                        pc <= pc + imm_from_id;
                    end
                    if (opcode_from_id == `JALR) begin // treat as wrong
                    end
                    if (ins[6 : 0] == 7'b1100011) begin // branch
                        if (pre_bits[pc[6 : 2]][1] == 1'b1) begin
                            pc <= pc + imm_from_id;
                            is_br <= 1'b1;
                        end else begin
                            pc <= pc + 4;
                            is_br <= 1'b0;
                        end
                    end
                    if (opcode_from_id < 6'd3 || opcode > 6'd10) pc <= pc + 4; // others
                end
            end
        end
    end

    // update pre_bits
    always@ (posedge clk) begin
        if (upt_en) begin
            if (is_jump) begin
                if (pre_bits[pre_id] < 2'b11) pre_bits[pre_id] <= pre_bits[pre_id] + 1;
            end else begin
                if (pre_bits[pre_id] > 2'b00) pre_bits[pre_id] <= pre_bits[pre_id] - 1;
            end
        end
    end
endmodule
`endif