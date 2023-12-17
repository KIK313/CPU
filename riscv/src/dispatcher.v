module dispatcher(
    input wire clk,
    input wire rst,
    input wire rdy,
    
    // communicate with insFetch
    input wire issue_en,
    input wire[31 : 0] pc,
    input wire[5 : 0] opcode,
    input wire[5 : 0] rd,
    input wire[5 : 0] rs1,
    input wire[5 : 0] rs2,
    input wire[31 : 0] imm,
    input wire is_br,

    input wire rob_id
);  
endmodule