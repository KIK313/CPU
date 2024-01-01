module Rob(
    input wire clk,
    input wire rst,
    input wire rdy,

    // communicate with dispatcher
    input wire issue_en,
    input wire[5 : 0] issue_opcode,
    input wire[4 : 0] issue_rd,
    input wire[4 : 0] issue_pre_reg_id,
    input wire[31 : 0] issue_val,
    input wire[31 : 0] issue_des_pc,
    input wire issue_pre_br,
    input wire issue_tr_br,
    output wire free_rob_id,

    output wire clear,

    //communicate with insFetch
    output wire is_full,
    output reg change_pc_en,
    output reg[31 : 0] new_pc,
    output reg pre_upt_en,
    output reg[4 : 0] pre_upt_id,
    output reg is_jump,

    // update from lsb
    input wire lsb_upt_en,
    input wire lsb_upt_rob_id,
    input wire[31 : 0] lsb_upt_val, 

    // update from alu
    input wire alu_upt_en,
    input wire[3 : 0] alu_upt_rob_id,
    input wire[31 : 0] alu_upt_val,
    input wire[31 : 0] alu_upt_pc,
    input wire is_tr_br,

    // to update vals in rs and lsb
    output reg is_rob_commit,
    output reg upt_rob_tag,
    output reg[31: 0] upt_rob_val,
    
    // to let store in lsb prepare to work
    output reg is_rob_store,
    
    output reg[4 : 0] upt_reg_id
);
    reg[3 : 0] head;
    reg[3 : 0] tail;
    reg[3 : 0] siz;

    reg[5 : 0] opcode[15 : 0];
    reg[4 : 0] rd[15 : 0];
    reg[31 : 0] val[15 : 0];
    reg[31 : 0] des_pc[15 : 0];
    reg[31 : 0] pre_reg_id[15 : 0];
    reg is_busy[15 : 0];
    reg is_rdy[15 : 0];
    reg br_tr_bit[15 : 0];
    reg br_pre_bit[15 : 0];
    
    reg is_clear;
    assign free_rob_id = (tail + 1) & (4'd15);
    always @(posedge clk) begin
        if (rst) begin
            head <= 4'd0;
            tail <= 4'd15;
            is_clear <= 0;
        end else if (rdy) begin
            
        end
    end

    always @(posedge clk) begin
        
    end
endmodule