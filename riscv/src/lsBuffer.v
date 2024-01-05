`ifndef lsBuffer
`define lsBuffer

`include"macros.v"

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
    input wire is_issue,
    input wire[3 : 0] issue_rob_id,
    input wire[5 : 0] issue_opcode,
    input wire[31 : 0] issue_imm,
    input wire[4 : 0] issue_rd,
    input wire[31 : 0] issue_Vi,
    input wire[3 : 0] issue_Qi,
    input wire issue_Ri,
    input wire[31 : 0] issue_Vj,
    input wire[3 : 0] issue_Qj,
    input wire issue_Rj,     

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

    // to update ROB and RS
    output reg ls_rdy,
    output reg[3 : 0] ls_rob_tag,
    output reg[31 : 0] ls_upt_val
);
    // update from lsBuffer last load
    reg is_load_upt;
    reg[31 : 0] upt_val;
    reg[3 : 0] upt_rob_tag;

    reg[3 : 0] head;
    reg[3 : 0] tail;
    reg[3 : 0] siz;
    reg[3 : 0] next_free;
    reg[3 : 0] last_commit_pos;

    reg[3 : 0] rob_id[15 : 0];
    reg[4 : 0] rd[15 : 0];
    reg[31 : 0] imm[15 : 0];
    reg[5 : 0] opcode[15 : 0];
    reg[31 : 0] Vi[15 : 0];
    reg[3 : 0] Qi[15 : 0];
    reg Ri[15 : 0];
    reg[31 : 0] Vj[15 : 0];
    reg[3 : 0] Qj[15 : 0];
    reg Rj[15 : 0];
    reg is_commit[15 : 0];
    reg is_busy[15 : 0]; 
    reg is_waiting[15 : 0];
    assign is_full = siz[3] && siz[2]; // >= 12
    wire is_upt;
    assign is_upt = (!clear && rdy && is_busy[head] && is_waiting[head] && ls_done && opcode[head] < `OP_SB);
    integer i;
    always @(*) begin
        siz = 0;
        for (i = 0; i < 16; i = i + 1) begin
            if (is_busy[i]) siz = siz + 1;
        end
    end
    always @(posedge clk) begin
        if (rst) begin
            is_load_upt <= 1'b0;
            ls_rdy <= 1'b0;
            head <= 4'b0000; tail <= 4'b1111;
            next_free <= 4'b0000; last_commit_pos <= 4'b1111;
            for (i = 0; i < 16; i = i + 1) begin
                is_busy[i] <= 0;
                is_commit[i] <= 0;
                is_waiting[i] <= 0;
                Qi[i] <= 4'b0;
                Qj[i] <= 4'b0;
            end    
        end else if(rdy) begin
            ls_rdy <= is_upt;
            is_load_upt <= is_upt;
            if (clear) begin 
                tail <= last_commit_pos;
                next_free <= (last_commit_pos + 1) & 4'b1111;
                for (i = 0; i < 16; i = i + 1) begin
                    if (!is_commit[i]) begin
                        is_busy[i] <= 0;
                        is_commit[i] <= 0;
                        is_waiting[i] <= 0;
                    end
                end
            end else begin 
                if (is_issue) begin
                    is_busy[next_free] <= 1'b1;
                    is_commit[next_free] <= 1'b0;
                    is_waiting[next_free] <= 1'b0;
                    rob_id[next_free] <= issue_rob_id;
                    opcode[next_free] <= issue_opcode;
                    rd[next_free] <= issue_rd;
                    Vi[next_free] <= issue_Vi; Qi[next_free] <= issue_Qi; Ri[next_free] <= issue_Ri;
                    Vj[next_free] <= issue_Vj; Qj[next_free] <= issue_Qj; Rj[next_free] <= issue_Rj;
                    imm[next_free] <= issue_imm;
                    tail <= (tail + 1) & 4'b1111;
                    next_free <= (next_free + 1) & 4'b1111;
                end
            end                
            if (is_busy[head] && Ri[head] && Rj[head]) begin
                if (opcode[head] >= `OP_SB) begin // store
                    if (is_waiting[head] && ls_done) begin
                        is_busy[head] <= 1'b0;
                        head <= (head + 1) & 4'b1111;
                        ls_sig <= 1'b0;
                    end
                    if (!is_waiting[head] && is_commit[head]) begin
                        is_waiting[head] <= 1'b1;
                        ls_sig <= 1'b1;
                        store_val <= Vj[head];
                        load_or_store <= 1'b1;
                        ls_addr <= Vi[head] + imm[head]; 
                        if (opcode[head] == `OP_SB) len <= 3'b001;
                        if (opcode[head] == `OP_SH) len <= 3'b010;                        
                        if (opcode[head] == `OP_SW) len <= 3'b100;
                    end
                end else if (!clear) begin // load
                    if (is_waiting[head] && ls_done) begin
                        ls_rob_tag <= rob_id[head];
                        case (opcode[head])
                            `OP_LB: begin
                                ls_upt_val <= {{24{ls_data[7]}}, ls_data[7 : 0]};
                                upt_val <= {{24{ls_data[7]}}, ls_data[7 : 0]};
                            end
                            `OP_LH: begin
                                ls_upt_val <= {{16{ls_data[15]}}, ls_data[15 : 0]};
                                upt_val <= {{16{ls_data[15]}}, ls_data[15 : 0]};                                
                            end
                            `OP_LW: begin
                                ls_upt_val <= ls_data;
                                upt_val <= ls_data;
                            end
                            `OP_LBU: begin
                                ls_upt_val <= {24'b0, ls_data[7 : 0]};
                                upt_val <= {24'b0, ls_data[7 : 0]};
                            end
                            `OP_LHU: begin
                                ls_upt_val <= {16'b0, ls_data[15 : 0]};
                                upt_val <= {16'b0, ls_data[15 : 0]};
                            end
                        endcase
                        is_busy[head] <= 1'b0;
                        last_commit_pos <= head;
                        head <= (head + 1) & 4'b1111;
                        ls_sig <= 1'b0;
                    end
                    if (!is_waiting[head]) begin
                        is_waiting[head] <= 1'b1;
                        ls_sig <= 1'b1;
                        load_or_store <= 1'b0;
                        ls_addr <= Vi[head] + imm[head];
                        if (opcode[head] == `OP_LB || opcode[head] == `OP_LBU) 
                            len <= 3'b001;
                        if (opcode[head] == `OP_LH || opcode[head] == `OP_LHU) 
                            len <= 3'b010;
                        if (opcode[head] == `OP_LW) len <= 3'b100;
                    end
                end
            end
            if (is_rob_store) begin
                for (i = 0; i < 16; i = i + 1) begin
                    if (is_busy[i] && rob_id[i] == rob_top_id) begin
                        is_commit[i] <= 1'b1;
                        last_commit_pos <= i;
                    end
                end
            end

            if (alu_done) begin
                for (i = 0; i < 16; i = i + 1) begin
                    if (!Ri[i] && Qi[i] == upt_tag_from_alu) begin
                        Ri[i] <= 1'b1;
                        Vi[i] <= upt_val_from_alu;
                    end
                    if (!Rj[i] && Qj[i] == upt_tag_from_alu) begin
                        Rj[i] <= 1'b1;
                        Vj[i] <= upt_val_from_alu;
                    end 
                end
            end

            if (rob_commit) begin
                for (i = 0; i < 16; i = i + 1) begin
                    if (!Ri[i] && Qi[i] == upt_tag_from_rob) begin
                        Ri[i] <= 1'b1;
                        Vi[i] <= upt_val_from_rob;
                    end
                    if (!Rj[i] && Qj[i] == upt_tag_from_rob) begin
                        Rj[i] <= 1'b1;
                        Vj[i] <= upt_val_from_rob;
                    end 
                end
            end

            if (is_load_upt) begin
                for (i = 0; i < 16; i = i + 1) begin
                    if (!Ri[i] && Qi[i] == upt_rob_tag) begin
                        Ri[i] <= 1'b1;
                        Vi[i] <= upt_val;
                    end
                    if (!Rj[i] && Qj[i] == upt_rob_tag) begin
                        Rj[i] <= 1'b1;
                        Vj[i] <= upt_val;
                    end 
                end               
            end
        end
    end

endmodule
`endif