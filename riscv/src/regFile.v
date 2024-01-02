module regFile(
    input wire clk, 
    input wire rst,
    input wire rdy, 

    // communicate with dispatcher
    input wire issue_sig,
    input wire[4 : 0] issue_rd,
    input wire[3 : 0] issue_rob_tag,
    input wire[4 : 0] reg1,
    output reg[31 : 0] val1,
    output reg[1 + 3 : 0] rob_tag1, // highest bit 1 -> tag / 0 -> no tag 
    input wire[4 : 0] reg2,
    output reg[31 : 0] val2,
    output reg[1 + 3 : 0] rob_tag2, 

    // communicate with rob
    input wire clear, 
    input wire commit_sig, // clear and commit_sig can be at the same time !!   
    input wire[4 : 0] commit_reg,
    input wire[31 : 0] commit_val,
    input wire[3 : 0] commit_rob_tag
);
    reg[31 : 0] reg_val[31 : 0]; // reg[0] === 0
    reg is_tag[31 : 0]; // 0 -> no tag cover 
    reg[3 : 0] rob_tag[31 : 0];
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                reg_val[i] <= 32'b0;
                rob_tag[i] <= 4'b0000;
                is_tag[i] <= 1'b0;
            end
        end else if (rdy) begin
            // modify val
            if (commit_sig && (commit_reg != 5'b00000)) begin 
                reg_val[commit_reg] <= commit_reg;
            end
            
            // modify tag
            if (!clear) begin 
                for (i = 0; i < 32; i = i + 1) begin
                    is_tag[i] <= 1'b0;
                end
            end else begin
                if (commit_sig && (commit_reg != 5'b00000)) begin
                    if (rob_tag[commit_reg] == commit_rob_tag 
                        && !(issue_sig && issue_rd == commit_reg)) begin
                            is_tag[commit_reg] <= 1'b0;
                    end  
                end
                if (issue_sig && (issue_rd != 5'b00000)) begin
                    is_tag[issue_rd] <= 1'b1;
                    rob_tag[issue_rd] <= issue_rob_tag;
                end
            end
        end
    end
    // read 2 regs
    always @(*) begin
        if (!rst && rdy) begin
            if (commit_sig && commit_reg != 5'b00000 && 
                commit_reg == reg1 && commit_rob_tag == rob_tag[reg1]) begin
                val1 = commit_val;
                rob_tag1 = {1'b0, {4{1'b0}}};
            end else begin
                val1 = reg_val[reg1];
                rob_tag1 = {is_tag[reg1], rob_tag[reg1]};
            end
        end
    end
    always @(*) begin
        if (!rst && rdy) begin
            if (commit_sig && commit_reg != 5'b00000 && 
                commit_reg == reg2 && commit_rob_tag == rob_tag[reg2]) begin
                val2 = commit_val;
                rob_tag2 = {1'b0, {4{1'b0}}};
            end else begin
                val2 = reg_val[reg2];
                rob_tag2 = {is_tag[reg2], rob_tag[reg2]};
            end            
        end
    end

endmodule