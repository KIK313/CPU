module insCache(
    input wire clk,
    input wire rst,
    input wire rdy,

    // communicate with insfetch
    input wire[31 : 0] pc_addr, // 17 -- 0 valid // the least two bits 00
    output wire hit,
    output wire[31 : 0] ins_out,

    // communicate with memCtrl
    input wire mem_valid,
    input wire[63 : 0] ins_blk,
    output reg mem_en,
    output reg[31 : 0] addr_to_mem
);
    reg valid_bit[31 : 0];
    reg[63 : 0] ins_line[31 : 0];  
    reg[17 : 8] tag_line[31 : 0]; 
    // 17 -> 8 tag / 7 -> 3 cache line / 2 -> 2 cache blk / 1 -> 0 00
    reg is_waiting;
    
    
    assign hit = valid_bit[pc_addr[7 : 3]] && (tag_line[pc_addr[7 : 3]] == pc_addr[17 : 8]);
    assign ins_out = hit ? (pc_addr[2] == 1'b0 ? ins_line[pc_addr[7 : 3]][31 : 0]
                                               : ins_line[pc_addr[7 : 3]][63 : 32]) : 32'b0;
    integer i;
    
    always @(posedge  clk) begin
        if (rst) begin
            for (i = 0; i < 31; i = i + 1) begin
                valid_bit[i] = 1'b0; 
            end 
            mem_en <= 1'b0;
            is_waiting <= 1'b0;
        end else if (rdy) begin
            if (!is_waiting) begin
                if (!hit) begin                
                    mem_en <= 1'b1;
                    addr_to_mem <= pc_addr;
                    is_waiting <= 1'b1;
                end
            end else begin
                if (mem_valid) begin
                    mem_en <= 1'b0;
                    is_waiting <= 1'b0;
                    ins_line[pc_addr[7 : 3]] <= ins_blk[63 : 0]; 
                    valid_bit[pc_addr[7 : 3]] <= 1'b1;
                    tag_line[pc_addr[7 : 3]] <= pc_addr[17 : 8];
                end               
            end    
        end
    end
endmodule