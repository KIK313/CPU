module memCtr (
    input wire clk,
    input wire rst,
    input wire rdy,
    
    // communicate with ram
    input wire[7:0] mem_in, 
    output reg[7:0] mem_out,
    output reg[31:0] mem_addr,
    output reg mem_en,
    output reg mem_wr,

    // communicate with insCache
    input wire ins_fetch_sig, 
    input wire[31:0] ins_addr,
    output reg ins_fetch_done,
    output reg[31:0] ins_data,
    
    // communicate with lsbuffer
    input wire ls_sig,
    input wire ls_wr, // read 1, write 0
    input wire[2:0] len, 
    input wire[31:0] ls_addr,
    input wire[31:0] store_val,
    output reg ls_done,
    output reg[31:0] ls_data
    );

    parameter EASE = 2'b00;
    parameter LOAD = 2'b01;
    parameter STORE = 2'b10;
    parameter INFET = 2'b11;
    reg[1:0] state; // 00 at ease, 01 load, 10, store, 11 ins_fetch  
    reg[1:0] 
    
    always @(posedge clk) begin
        if (rst) begin
            
        end 
        else if (!rdy) begin
            
        end 
        else begin
            case (state) 
                EASE: begin
                    if (ins_fetch_sig) begin
                        state <= ls_wr ? LOAD : STORE;
                        ls_done <= 0;
                        ls_data <= 32'd0;
                        ins_fetch_done <= 0;
                        
                        len <= 0  

                    end
                    else if (ls_sig) begin
                        state <= 
                    end 
                end    
                LOAD: begin
                
                end
                STORE: begin

                end
                INFET: begin

                end
            endcase
        end   
    end
endmodule