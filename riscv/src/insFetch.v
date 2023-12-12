module insFetch(
    input wire clk,
    input wire rst,
    input wire rdy,

    // communicate with insCache
    input wire hit,
    input wire[31 : 0] ins,
    output wire[31 : 0] addr_to_icache,
    
    // communicate with dispatcher 
    output reg issue_en,
    output reg[4 : 0] rs1,
    output reg[4 : 0] rs2,
    output reg[31 : 0] imm, 

    // communicate with rs,rob,lsb
    input wire rs_next_full,
    input wire rob_next_full,
    input wire lsb_next_full,

    // communicate with ROB about branch
    input wire clear,
    input wire[31 : 0] new_pc
);
    reg[31 : 0] pc; 
    reg[1 : 0] pre_bits[15 : 0];

    always@ (posedge clk) begin
        if (rst) begin
            pc <= 32'b0;
            issue_en <= 1'b0;
            
        end else if (rdy) begin

        end
    end 

endmodule