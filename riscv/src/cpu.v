// RISCV32I CPU top module
// port modification allowed for debugging purposes
`ifndef CPU 
`define CPU

`include "memCtr.v"
`include "insCache.v"
`include "lsBuffer.v"
`include "insFetch.v"
`include "decoder.v"
`include "dispatcher.v"
`include "regFile.v"
`include "Rob.v"
`include "Rs.v"
`include "ALU.v"

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)
    wire clear;
    wire insCache_fetch_sig;
    wire[31 : 0] insCache_fetch_addr;
    wire memCtr_ins_done;
    wire[63 : 0] memCtr_ins_data;
    wire ls_work_sig;
    wire ls_wr;
    wire[2 : 0] ls_work_len;
    wire[31 : 0] ls_work_addr;
    wire[31 : 0] ls_work_val;
    wire memCtr_ls_done;
    wire[31 : 0] memCtr_ls_data;
memCtr _memCtr (
    .clk (clk_in),
    .rst (rst_in),
    .rdy (rdy_in),
    .io_buffer_full(io_buffer_full),
    .clear(clear),
    
    .mem_in (mem_din), 
    .mem_out (mem_dout),
    .mem_addr (mem_a),
    .mem_wr (mem_wr), 

    // communicate with insCache
    .ins_fetch_sig (insCache_fetch_sig), 
    .ins_addr (insCache_fetch_addr),
    .ins_fetch_done (memCtr_ins_done), 
    .ins_data (memCtr_ins_data),  
    
    // communicate with lsbuffer
    .ls_sig (ls_work_sig),
    .ls_wr (ls_wr), 
    .len (ls_work_len), 
    .ls_addr (ls_work_addr),
    .store_val (ls_work_val),
    .ls_done (memCtr_ls_done),  
    .ls_data (memCtr_ls_data)
);
  wire[31 : 0] insFetch_insCache_pc;
  wire insCache_hit;
  wire[31 : 0] insCache_ins;
insCache _insCache(
    .clk (clk_in),
    .rst (rst_in),
    .rdy (rdy_in),

    // communicate with insfetch
    .pc_addr (insFetch_insCache_pc), 
    .hit (insCache_hit),
    .ins_out (insCache_ins),

    // communicate with memCtrl
    .mem_valid (memCtr_ins_done),
    .ins_blk (memCtr_ins_data),
    .mem_en (insCache_fetch_sig),
    .addr_to_mem (insCache_fetch_addr)
);
  wire insFetch_en;
  wire[31 : 0] insFetch_pc;
  wire[5 : 0] insFetch_opcode;
  wire[4 : 0] insFetch_rd;
  wire[4 : 0] insFetch_rs1;
  wire[4 : 0] insFetch_rs2;
  wire[31 : 0] insFetch_imm;
  wire insFetch_is_br; 

  wire lsb_full;
  wire rob_full;
  
  wire[31 : 0] rob_new_pc;
  wire rob_upt_pre_en;
  wire[4 : 0] rob_upt_pre_reg;
  wire rob_upt_pre_is_br;

insFetch _insFetch(
    .clk (clk_in),
    .rst (rst_in),
    .rdy (rdy_in),

    // communicate with insCache
    .hit (insCache_hit),
    .ins (insCache_ins),
    .addr_to_icache (insFetch_insCache_pc), 
    
    // communicate with dispatcher 
    .issue_en (insFetch_en),
    .once_pc (insFetch_pc), 
    .opcode (insFetch_opcode),
    .rd (insFetch_rd), 
    .rs1 (insFetch_rs1),
    .rs2 (insFetch_rs2),
    .imm (insFetch_imm),
    .is_br (insFetch_is_br),

    // communicate with rs,rob,lsb
    .rob_full (rob_full),
    .lsb_full (lsb_full),

    // communicate with ROB about branch
    .clear (clear),
    .new_pc (rob_new_pc),

    // rob pre_bits
    .upt_en (rob_upt_pre_en),
    .pre_id (rob_upt_pre_reg),
    .is_jump (rob_upt_pre_is_br)
);
  wire dispatch_issue_sig;
  wire dispatch_rob_en;
  wire dispatch_rs_en;
  wire dispatch_lsb_en;
  wire[31 : 0] issue_pc;
  wire[31 : 0] issue_imm;
  wire[4 : 0] issue_pre_reg;
  wire issue_is_br;
  wire[5 : 0] issue_opcode;
  wire[31 : 0] issue_Vi; wire[3 : 0] issue_Qi; wire issue_Ri;
  wire[31 : 0] issue_Vj; wire[3 : 0] issue_Qj; wire issue_Rj;
  wire[3 : 0] issue_rob_id;
dispatcher _dispatcher(
    .clk (clk_in),
    .rst (rst_in),
    .rdy (rdy_in),
    
    // communicate with insFetch
    .issue_en (insFetch_en),
    .pc (insFetch_pc), 
    .opcode (insFetch_opcode),
    .rd (insFetch_rd),
    .rs1 (insFetch_rs1),
    .rs2 (insFetch_rs2),
    .imm (insFetch_imm),
    .is_br (insFetch_is_br),

    // communicate with RF
    .issue_sig (dispatch_issue_sig),
    .query_rg1 (rf_rg1),
    .query_rg2 (rf_rg2),
    .issue_reg_id (rf_rd),
    .issue_rob_tag (rf_rob_tag),
    .val1 (rf_v1),
    .tag1 (rf_tag1),
    .val2 (rf_v2),
    .tag2 (rf_tag2),

    // ALU BroadCast
    .is_ok (alu_upt_en),
    .val_from_alu (alu_upt_val),
    .rob_id_from_alu(alu_upt_rob_id),

    // communicate with rs
    .dispatch_rs_en (dispatch_rs_en),
    .imm_from_dpc (issue_imm),
    .once_pc_from_dpc (issue_pc),
    

    // commnunicate with rob
    .rob_id (free_rob_id),
    .is_clear (clear),
    .dispatch_rob_en (dispatch_rob_en),
    .pre_reg_id (issue_pre_reg),
    .is_br_from_dpc (issue_is_br),
    // communicate with lsb
    .dispatch_lsb_en (dispatch_lsb_en),


    // dispatch what dispatcher have
    .dis_opcode (issue_opcode),
    .dis_rob_id (issue_rob_id),
    .Vi(issue_Vi),
    .Vj(issue_Vj),
    .Qi(issue_Qi),
    .Qj(issue_Qj),
    .Oi(issue_Ri),
    .Oj(issue_Rj) 
);
  wire[4 : 0] rf_rd;
  wire[3 : 0] rf_rob_tag;
  wire[4 : 0] rf_rg1;
  wire[31 : 0] rf_v1;
  wire[4 : 0] rf_tag1;
  wire[4 : 0] rf_rg2;
  wire[31 : 0] rf_v2;
  wire[4 : 0] rf_tag2; 
regFile _regFile(
    .clk (clk_in), 
    .rst (rst_in),
    .rdy (rdy_in), 

    // communicate with dispatcher
    .issue_sig (dispatch_issue_sig),
    .issue_rd (rf_rd),
    .issue_rob_tag (rf_rob_tag),
    .reg1 (rf_rg1),
    .val1 (rf_v1),
    .rob_tag1 (rf_tag1), 
    .reg2 (rf_rg2),
    .val2 (rf_v2),
    .rob_tag2 (rf_tag2), 

    // communicate with rob
    .clear (clear), 
    .commit_sig (is_rob_commit), // clear and commit_sig can be at the same time !!   
    .commit_reg (rob_commit_reg),
    .commit_val (rob_commit_val),
    .commit_rob_tag (rob_commit_id)
);
  wire ls_upt_en;
  wire[3 : 0] ls_upt_rob_id;
  wire[31 : 0] ls_upt_val;
lsBuffer _lsBuffer(
    .clk (clk_in),
    .rst (rst_in),
    .rdy (rdy_in),

    // communicate with memCtrl
    .ls_done (memCtr_ls_done),
    .ls_data (memCtr_ls_data),
    .ls_sig (ls_work_sig),
    .load_or_store (ls_wr), // load 0, store 1
    .len (ls_work_len),    
    .ls_addr (ls_work_addr), 
    .store_val (ls_work_val),

    // communicate with ifetch
    .is_full (lsb_full),

    //communicate with dispatcher
    .is_issue (dispatch_lsb_en),
    .issue_rob_id (issue_rob_id),
    .issue_opcode (issue_opcode),
    .issue_imm (issue_imm), 
    .issue_rd (insFetch_rd),
    .issue_Vi (issue_Vi),
    .issue_Qi (issue_Qi),
    .issue_Ri (issue_Ri),
    .issue_Vj (issue_Vj),
    .issue_Qj (issue_Qj), 
    .issue_Rj (issue_Rj),     

    // update from ALU
    .alu_done(alu_upt_en),
    .upt_tag_from_alu(alu_upt_rob_id),
    .upt_val_from_alu(alu_upt_val),

    // update from ROB
    .rob_commit (is_rob_commit),
    .upt_tag_from_rob (rob_commit_id),
    .upt_val_from_rob (rob_commit_val),

    .clear (clear),
    .is_rob_store (is_rob_store),
    .rob_top_id (rob_commit_id),

    // to update ROB and RS
    .ls_rdy (ls_upt_en),
    .ls_rob_tag (ls_upt_rob_id),
    .ls_upt_val (ls_upt_val)
);
  wire is_rob_commit;
  wire[3 : 0] rob_commit_id;
  wire[31 : 0] rob_commit_val;
  wire is_rob_store;
  wire[4 : 0] rob_commit_reg;
  wire[3 : 0] free_rob_id;
Rob _Rob(
    .clk (clk_in),
    .rst (rst_in),
    .rdy (rdy_in),

    // communicate with dispatcher
    .issue_en (dispatch_rob_en),
    .issue_opcode (issue_opcode),
    .issue_rd (insFetch_rd),
    .issue_pre_reg_id (issue_pre_reg),
    .issue_pre_br (issue_is_br),
    .free_rob_id (free_rob_id),

    .clear(clear),

    //communicate with insFetch
    .is_full (rob_full),
    .new_pc (rob_new_pc),
    .pre_upt_en (rob_upt_pre_en),
    .pre_upt_reg_id (rob_upt_pre_reg),
    .is_jump (rob_upt_pre_is_br), 

    // update from lsb
    .lsb_upt_en (ls_upt_en),
    .lsb_upt_rob_id (ls_upt_rob_id),
    .lsb_upt_val (ls_upt_val), 

    // update from alu
    .alu_upt_en(alu_upt_en),
    .alu_upt_rob_id(alu_upt_rob_id),
    .alu_upt_val(alu_upt_val),
    .alu_upt_pc(alu_upt_br_pc),
    .is_tr_br(alu_upt_is_br),

    // to update vals in rs and lsb
    .is_rob_commit(is_rob_commit),
    .upt_rob_tag(rob_commit_id),
    .upt_rob_val(rob_commit_val),
    
    // to let store in lsb prepare to work
    .is_rob_store (is_rob_store),
    
    // to update RF
    .upt_rf_reg_id (rob_commit_reg)
);
  wire alu_work_en;
  wire[5 : 0] rs_alu_opcode;
  wire[3 : 0] rs_alu_rob_id;
  wire[31 : 0] rs_alu_val1;
  wire[31 : 0] rs_alu_val2;
  wire[31 : 0] rs_alu_pc;
  wire[31 : 0] rs_alu_imm;
Rs _Rs(
    .clk (clk_in),
    .rst (rst_in),
    .rdy (rdy_in),

    .clear (clear),

    // communicate with dispatcher
    .is_issue (dispatch_rs_en),
    .issue_opcode (issue_opcode),
    .issue_rob_id (issue_rob_id),
    .issue_Vi (issue_Vi),
    .issue_Qi (issue_Qi),
    .issue_Ri (issue_Ri),
    .issue_Vj (issue_Vj),
    .issue_Qj (issue_Qj),
    .issue_Rj (issue_Rj),
    .issue_imm (issue_imm),
    .issue_pc (issue_pc),

    // communicate with ALU
    .work_en (alu_work_en),
    .rob_id_from_rs (rs_alu_rob_id),
    .opcode_from_rs (rs_alu_opcode),
    .val1 (rs_alu_val1),
    .val2 (rs_alu_val2), 
    .imm_from_rs (rs_alu_imm),
    .pc_from_rs (rs_alu_pc),

    // update from ALU
    .is_alu_ok (alu_upt_en),
    .rob_id_from_alu (alu_upt_rob_id),
    .res_from_alu (alu_upt_val),

    // update from ROB
    .is_rob_commit (is_rob_commit),
    .rob_id_from_rob (rob_commit_id),
    .res_from_rob (rob_commit_val),

    // update from LSB  
    .is_lsb_ok (ls_upt_en),
    .rob_id_from_lsb (ls_upt_rob_id),
    .res_from_lsb (ls_upt_val)
);
  wire alu_upt_en;
  wire[31 : 0] alu_upt_val;
  wire[3 : 0] alu_upt_rob_id;
  wire alu_upt_is_br;
  wire[31 : 0] alu_upt_br_pc;
ALU _ALU(
    .clk (clk_in),
    .rst (rst_in),
    .rdy (rdy_in),
    
    // communicate with RS
    .work_en (alu_work_en),
    .rob_id (rs_alu_rob_id),
    .opcode (rs_alu_opcode), 
    .rs1 (rs_alu_val1),
    .rs2 (rs_alu_val2),
    .imm (rs_alu_imm), 
    .pc (rs_alu_pc),
    .clear (clear),
    .is_ok (alu_upt_en), 
    .res (alu_upt_val),
    .ret_rob_id (alu_upt_rob_id),
    .is_jump (alu_upt_is_br),
    .jump_pc (alu_upt_br_pc)
);
endmodule
`endif