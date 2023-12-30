module Rob(
    input wire clk,
    input wire rst,
    input wire rdy,

    // communicate with dispatcher
    input wire issue_en,
    input wire[5 : 0] opcode_from_dpc,
    input wire[4 : 0] rd_from_dpc,
    output wire free_rob_id,

    //communicate with insFetch
    output wire is_full,
    output reg clear_to_insFetch,
    output reg[31 : 0] new_pc,
    output reg pre_upt_en,
    output reg[4 : 0] pre_upt_id,
    output reg is_jump


    // communicate with rf


);
    reg[3 : 0] head;
    reg[3 : 0] tail;
    reg[5 : 0] opcode[15 : 0];
    reg[4 : 0] rd[15 : 0];
    reg[31 : 0] val[15 : 0];
    reg[31 : 0] ins_pc[15 : 0];
    reg rdy_bit[15 : 0];
    reg cmp_bit[15 : 0];
    reg pre_bit[15 : 0];
    
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