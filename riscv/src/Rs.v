module Rs(
    input wire clk,
    input wire rst,
    input wire rdy,

    input clear,

    // communicate with dispatcher
    input wire is_issue,
    input wire[5 : 0] issue_opcode,
    input wire[3 : 0] issue_rob_id,
    input wire[31 : 0] issue_Vi,
    input wire[3 : 0] issue_Qi,
    input wire issue_Ri,
    input wire[31 : 0] issue_Vj,
    input wire[3 : 0] issue_Qj,
    input wire issue_Rj,
    input wire[31 : 0] issue_imm,
    input wire[31 : 0] issue_pc,

    // communicate with ALU
    output reg work_en,
    output reg[3 : 0] rob_id_from_rs,
    output reg[5 : 0] opcode_from_rs,
    output reg[31 : 0] val1,
    output reg[31 : 0] val2,
    output reg[31 : 0] imm_from_rs,
    output reg[31 : 0] pc_from_rs,
    // update from ALU
    input wire is_alu_ok,
    input wire[3 : 0] rob_id_from_alu,
    input wire[31 : 0] res_from_alu,

    // update from ROB
    input wire is_rob_commit,
    input wire[3 : 0] rob_id_from_rob,
    input wire[31 : 0] res_from_rob,

    // update from LSB  
    input wire is_lsb_ok,
    input wire[3 : 0] rob_id_from_lsb,
    input wire[31 : 0] res_from_lsb
);
    reg is_busy[15 : 0];
    reg[5 : 0] opcode[15 : 0];
    reg[3 : 0] rob_id[15 : 0];
    reg[31 : 0] Vi[15 : 0]; reg[3 : 0] Qi[15 : 0]; reg Ri[15 : 0];
    reg[31 : 0] Vj[15 : 0]; reg[3 : 0] Qj[15 : 0]; reg Rj[15 : 0];
    reg[31 : 0] imm[15 : 0]; reg[31 : 0] pc[15 : 0];

    reg[3 : 0] next_free;
    reg[3 : 0] rdy_pos;
    reg is_some_rdy;
    integer i;
    always @(*) begin
        next_free = 0;
        is_some_rdy = 0;
        for (i = 0; i < 16; i = i + 1) begin
            if (!is_busy[i]) next_free = i;      
            if (is_busy[i] && Ri[i] && Rj[i]) begin
                is_some_rdy = 1;
                rdy_pos = i;
            end
        end
    end
    always @(posedge clk) begin
        if (rst || clear) begin
            for (i = 0; i < 16; i = i + 1) begin
                is_busy[i] <= 1'b0;
            end
            work_en <= 1'b0;
        end else if (rdy) begin
            if (is_issue) begin
                is_busy[next_free] <= 1'b1;
                opcode[next_free] <= issue_opcode;
                rob_id[next_free] <= issue_rob_id;
                Vi[next_free] <= issue_Vi; Vj[next_free] <= issue_Vj;
                Qi[next_free] <= issue_Qi; Qj[next_free] <= issue_Qj;
                Ri[next_free] <= issue_Ri; Rj[next_free] <= issue_Rj;
                imm[next_free] <= issue_imm;
                pc[next_free] <= issue_pc;
            end
            if (is_some_rdy) begin
                work_en <= 1'b1;
                rob_id_from_rs <= rob_id[rdy_pos];
                opcode_from_rs <= opcode[rdy_pos];
                val1 <= Vi[rdy_pos]; val2 <= Vj[rdy_pos];
                imm_from_rs <= imm[rdy_pos]; pc_from_rs <= pc[rdy_pos];
            end else begin
                work_en <= 1'b0;
            end
            if (is_alu_ok) begin
                for (i = 0; i < 16; i = i + 1) begin
                    if (!Ri[i] && Qi[i] == rob_id_from_alu) begin
                        Ri[i] <= 1'b1;
                        Qi[i] <= 4'b0;
                        Vi[i] <= res_from_alu;
                    end
                    if (!Rj[i] && Qj[i] == rob_id_from_alu) begin
                        Rj[i] <= 1'b1;
                        Qj[i] <= 4'b0;
                        Vj[i] <= res_from_alu;
                    end
                end
            end
            if (is_rob_commit) begin
                for (i = 0; i < 16; i = i + 1) begin
                    if (!Ri[i] && Qi[i] == rob_id_from_rob) begin
                        Ri[i] <= 1'b1;
                        Qi[i] <= 4'b0;
                        Vi[i] <= res_from_rob;
                    end
                    if (!Rj[i] && Qj[i] == rob_id_from_rob) begin
                        Rj[i] <= 1'b1;
                        Qj[i] <= 4'b0;
                        Vj[i] <= res_from_rob;
                    end 
                end
            end
            if (is_lsb_ok) begin
                for (i = 0; i < 16; i = i + 1) begin
                    if (!Ri[i] && Qi[i] == rob_id_from_lsb) begin
                        Ri[i] <= 1'b1;
                        Qi[i] <= 4'b0;
                        Vi[i] <= res_from_lsb;
                    end
                    if (!Rj[i] && Qj[i] == rob_id_from_lsb) begin
                        Rj[i] <= 1'b1;
                        Qj[i] <= 4'b0;
                        Vj[i] <= res_from_lsb;
                    end 
                end                
            end
        end
    end    
endmodule