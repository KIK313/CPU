module lsBuffer(
    input wire clk,
    input wire rst,
    input wire rdy,

    // communicate with memCtrl
    input wire ls_done,
    input wire[31 : 0] ls_data,
    output reg ls_sig,
    output reg load_or_store, // load 0, store 1
    output reg[2 : 0] len,    
    output reg[31 : 0] ls_addr, 
    output reg[31 : 0] store_val,

    // communicate with ifetch
    output wire is_full,


    //communicate with dispatcher
    input wire[3 : 0] issue_rob_id,
    input wire[5 : 0] issue_opcode,
    input wire[31 : 0] issue_imm,
    input wire[31 : 0] Vi,
    input wire[3 : 0] Qi,
    input wire Ri,
    input wire[31 : 0] Vj,
    input wire[3 : 0] Qj,
    input wire Rj,     

    // update from ALU
    input wire alu_done,
    input wire[3 : 0] upt_tag_from_alu,
    input wire[31 : 0] upt_val_from_alu,

    // update from ROB
    input wire rob_commit,
    input wire[3 : 0] upt_tag_from_rob,
    input wire[31 : 0] upt_val_from_rob,

    input wire clear,
    input wire is_rob_store,
    input wire[3 : 0] rob_top_id,

    // to update ROB
    output reg ls_rob_rdy,
    output reg[31 : 0] ls_rob_tag,

    // to update RS
    output reg ls_rs_ok,
    output reg[3 : 0] upt_tag_from_lsb,
    output reg[31 : 0] upt_val_from_lsb
);
    // update from lsBuffer last load
    reg is_load_upt;
    reg[31 : 0] upt_val;
    reg[3 : 0] upt_rob_tag;

    reg[3 : 0] head;
    reg[3 : 0] tail;
    reg[3 : 0] siz;

    reg[31 : 0] imm[15 : 0];
endmodule