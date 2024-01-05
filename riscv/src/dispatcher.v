`ifndef DISPATCHER
`define DISPATCHER

`include "macros.v"

module dispatcher(
    input wire clk,
    input wire rst,
    input wire rdy,
    
    // communicate with insFetch
    input wire issue_en,
    input wire[31 : 0] pc,
    input wire[5 : 0] opcode,
    input wire[4 : 0] rd,
    input wire[4 : 0] rs1,
    input wire[4 : 0] rs2,
    input wire[31 : 0] imm,
    input wire is_br,

    // communicate with RF
    output wire issue_sig,
    output wire[4 : 0] query_rg1,
    output wire[4 : 0] query_rg2,
    output wire[4 : 0] issue_reg_id,
    output wire[3 : 0] issue_rob_tag,
    input wire[31 : 0] val1,
    input wire[4 : 0] tag1,
    input wire[31 : 0] val2,
    input wire[4 : 0] tag2,

    // ALU BroadCast
    input wire is_ok,
    input wire[31 : 0] val_from_alu,
    input wire[3 : 0] rob_id_from_alu,

    // communicate with rs
    output wire dispatch_rs_en,
    output wire[31 : 0] imm_from_dpc,
    output wire[31 : 0] once_pc_from_dpc,
    

    // commnunicate with rob
    input wire[3 : 0] rob_id,
    input wire is_clear,
    output wire dispatch_rob_en,
    output wire[4 : 0] pre_reg_id,
    output wire is_br_from_dpc,
    // communicate with lsb
    output wire dispatch_lsb_en,


    // dispatch what dispatcher have
    output wire[5 : 0] dis_opcode,
    output wire[3 : 0] dis_rob_id,
    output wire[31 : 0] Vi,
    output wire[31 : 0] Vj,
    output wire[3 : 0] Qi,
    output wire[3 : 0] Qj,
    output wire Oi,
    output wire Oj   
);  
    assign dis_opcode = opcode;
    assign dis_rob_id = rob_id;

    assign issue_sig = issue_en && rdy && !rst;
    assign query_rg1 = rs1;
    assign query_rg2 = rs2;
    assign issue_reg_id = rd;
    assign issue_rob_id = rob_id;
    
    assign dispatch_rs_en = !rst && rdy && issue_en && !is_ls;
    assign pre_reg_id = pc[6 : 2];
    assign imm_from_dpc = imm;
    assign once_pc_from_dpc = pc;
    assign is_br_from_dpc = is_br;
    assign Vi = tag1[4] ? (is_ok && tag1[3 : 0] == rob_id_from_alu ? val_from_alu : 32'b0) : val1;
    assign Qi = tag1[4] ? (is_ok && tag1[3 : 0] == rob_id_from_alu ? 4'b0 : tag1[3 : 0]) : 4'b0;
    assign Oi = tag1[4] ? (is_ok && tag1[3 : 0] == rob_id_from_alu ? 1'b1 : 1'b0) : 1'b1;
    assign Vj = tag2[4] ? (is_ok && tag2[3 : 0] == rob_id_from_alu ? val_from_alu : 32'b0) : val2;
    assign Qj = tag2[4] ? (is_ok && tag2[3 : 0] == rob_id_from_alu ? 4'b0 : tag2[3 : 0]) : 4'b0;
    assign Oj = tag2[4] ? (is_ok && tag2[3 : 0] == rob_id_from_alu ? 1'b1 : 1'b0) : 1'b1;

    assign dispatch_rob_en = !rst && rdy && issue_en;
    
    wire is_ls;
    assign is_ls = opcode >= `OP_LB && opcode <= `OP_SW;
    assign dispatch_lsb_en = !rst && rdy && issue_en && is_ls; 
    // if clear, ins woulb be rejected by rob,rs,lsb 

    always @(posedge clk) begin
        // just for fun
    end
endmodule
`endif