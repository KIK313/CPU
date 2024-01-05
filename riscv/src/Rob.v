`ifndef ROB
`define ROB

`include "macros.v"

module Rob(
    input wire clk,
    input wire rst,
    input wire rdy,

    // communicate with dispatcher
    input wire issue_en,
    input wire[5 : 0] issue_opcode,
    input wire[4 : 0] issue_rd,
    input wire[4 : 0] issue_pre_reg_id,
    input wire issue_pre_br,
    output wire[3 : 0] free_rob_id,

    output wire clear,

    //communicate with insFetch
    output wire is_full,
    output reg[31 : 0] new_pc,
    output reg pre_upt_en,
    output reg[4 : 0] pre_upt_reg_id,
    output reg is_jump,

    // update from lsb
    input wire lsb_upt_en,
    input wire[3 : 0] lsb_upt_rob_id,
    input wire[31 : 0] lsb_upt_val, 

    // update from alu
    input wire alu_upt_en,
    input wire[3 : 0] alu_upt_rob_id,
    input wire[31 : 0] alu_upt_val,
    input wire[31 : 0] alu_upt_pc,
    input wire is_tr_br,

    // to update vals in rs and lsb
    output reg is_rob_commit,
    output reg[3 : 0] upt_rob_tag,
    output reg[31: 0] upt_rob_val,
    
    // to let store in lsb prepare to work
    output reg is_rob_store,
    
    // to update RF
    output reg[4 : 0] upt_rf_reg_id
);
    reg[3 : 0] head;
    reg[3 : 0] siz;
    reg[3 : 0] next_free;

    reg[5 : 0] opcode[15 : 0];
    reg[4 : 0] rd[15 : 0];
    reg[31 : 0] val[15 : 0];
    reg[31 : 0] des_pc[15 : 0];
    reg[4 : 0] pre_reg_id[15 : 0];
    reg is_busy[15 : 0];
    reg is_rdy[15 : 0];
    reg br_tr_bit[15 : 0];
    reg br_pre_bit[15 : 0];
    
    reg is_clear;
    assign free_rob_id = next_free;
    assign clear = is_clear; // 1111
    assign is_full = siz[3] && siz[2];
    integer i;
    always @(*) begin
        siz = 0;
        for (i = 0; i < 16; i = i + 1) begin
            if (is_busy[i]) siz = siz + 1;
        end
    end
    always @(posedge clk) begin
        if (rst || is_clear) begin
            head <= 4'd0;
            next_free <= 4'b0;
            for (i = 0; i < 16; i = i + 1) begin
                is_busy[i] <= 1'b0;
                is_rdy[i] <= 1'b0;
                br_tr_bit[i] <= 1'b0;
            end
            is_clear <= 1'b0;
            pre_upt_en <= 1'b0;
            is_rob_store <= 1'b0;
        end else if (rdy) begin
            upt_rf_reg_id <= rd[head];
            if (issue_en) begin
                opcode[next_free] <= issue_opcode;
                rd[next_free] <= issue_rd;
                is_busy[next_free] <= 1'b1;
                is_rdy[next_free] <= issue_opcode >= `OP_SB && issue_opcode <= `OP_SW;
                pre_reg_id[next_free] <= issue_pre_reg_id;
                br_pre_bit[next_free] <= issue_pre_br;
                next_free <= (next_free + 1) & 4'b1111;
            end
            if (is_busy[head] && is_rdy[head]) begin
                is_rob_commit <= 1'b1;
                upt_rob_tag <= head;
                upt_rob_val <= val[head];
                if (opcode[head] >= `OP_BEQ && opcode[head] <= `OP_BGEU) begin
                    is_clear <= (br_tr_bit[head] ^ br_pre_bit[head]);
                    new_pc <= des_pc[head];
                    pre_upt_en <= 1'b1;
                    is_jump <= br_tr_bit[head];
                    pre_upt_reg_id <= pre_reg_id[head];
                end else if (opcode[head] == `OP_JALR) begin
                    pre_upt_en <= 1'b0;
                    new_pc <= des_pc[head];
                    is_clear <= 1'b1;
                end else begin
                    pre_upt_en <= 1'b0;
                end
                is_busy[head] <= 1'b0;
                head <= (head + 1) &  4'b1111;
            end else begin
                is_rob_commit <= 1'b0;
                pre_upt_en <= 1'b0;
            end

            if (is_busy[head] && opcode[head] >= `OP_SB && opcode[head] <= `OP_SW) begin
                is_rob_store <= 1'b1;
            end else is_rob_store <= 1'b0;

            if (alu_upt_en) begin
                is_rdy[alu_upt_rob_id] <= 1'b1;
                val[alu_upt_rob_id] <= alu_upt_val;
                des_pc[alu_upt_rob_id] <= alu_upt_pc;
                br_tr_bit[alu_upt_rob_id] <= is_tr_br;
            end

            if (lsb_upt_en) begin
               is_rdy[lsb_upt_rob_id] <= 1'b1;
               val[lsb_upt_rob_id] <= lsb_upt_val; 
            end
        end
    end
endmodule
`endif