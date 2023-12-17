module regFile #(parameter rob_width = 4) (
    input wire clk, 
    input wire rst,
    input wire rdy, 
    
    input wire clear, // clear rob_tag

    // read the value and tag of two regs
    input wire[4 : 0] reg1,
    output reg[31 : 0] val1,
    output reg[rob_width : 0] rob_tag1, // highest bit 1 -> tag / 0 -> no tag 
    input wire[4 : 0] reg2,
    output reg[31 : 0] val2,
    output reg[rob_width : 0] rob_tag2, 

    input wire issue_sig,
    input wire[4 : 0] issue_reg_id,
    input wire[rob_width - 1 : 0] issue_rob_tag,
    // commit the tag from rob
    input wire commit_sig, // commit_sig 1 -> commit / 0 -> no commit  
    input wire[4 : 0] commit_reg,
    input wire[31 : 0] commit_val,
    input wire[4 : 0] commit_rob_tag
);
    reg[31 : 0] reg_val[31 : 0]; // reg[0] === 0
    reg[31 : 0] is_tag; // 0 -> no tag cover 
    reg[rob_width-1 : 0] rob_tag[31 : 0];
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                reg_val[i] <= 32'b0;
                rob_tag[i] <= {rob_width{1'b0}};
            end
            is_tag <= {32{1'b0}};
        end else if (clear) begin
            is_tag <= {32{1'b0}};
        end else if (rdy) begin
            if (commit_sig && (commit_reg != 5'b00000)) begin
                reg_val[commit_reg] <= commit_val; // modify reg_val   
                if (rob_tag[commit_reg] == commit_rob_tag 
                    && !(issue_sig && issue_reg_id == commit_reg)) 
                        is_tag[commit_reg] <= 1'b0; // try to clear the tag 
            end
            
            // modify reg_tag 
            if (issue_sig && (issue_reg_id != 5'b00000)) begin
                is_tag[issue_reg_id] <= 1'b1;
                rob_tag[issue_reg_id] <= issue_rob_tag;
            end

            // // read 2 regs
            // if (commit_sig && commit_reg != 5'b00000 && 
            //     commit_reg == reg1 && commit_rob_tag == rob_tag[reg1]) begin
            //     val1 <= commit_val;
            //     rob_tag1 <= {1'b0, {rob_width{1'b0}}};
            // end else begin
            //     val1 <= reg_val[reg1];
            //     rob_tag1 <= {is_tag[reg1], rob_tag[reg1]};
            // end

            // if (commit_sig && commit_reg != 5'b00000 && 
            //     commit_reg == reg2 && commit_rob_tag == rob_tag[reg2]) begin
            //     val2 <= commit_val;
            //     rob_tag2 <= {1'b0, {rob_width{1'b0}}};
            // end else begin
            //     val2 <= reg_val[reg2];
            //     rob_tag2 <= {is_tag[reg2], rob_tag[reg2]};
            // end
        end
    end
    // read 2 regs
    always @(*) begin
        if (!rst && rdy) begin
            if (commit_sig && commit_reg != 5'b00000 && 
                commit_reg == reg1 && commit_rob_tag == rob_tag[reg1]) begin
                val1 = commit_val;
                rob_tag1 = {1'b0, {rob_width{1'b0}}};
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
                rob_tag2 = {1'b0, {rob_width{1'b0}}};
            end else begin
                val2 = reg_val[reg2];
                rob_tag2 = {is_tag[reg2], rob_tag[reg2]};
            end            
        end
    end

endmodule