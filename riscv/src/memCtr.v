module memCtr (
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire io_buffer_full,
    
    // communicate with ram
    input wire[7:0] mem_in, 
    output reg[7:0] mem_out,
    output reg[31:0] mem_addr,
    output reg mem_en,
    output reg mem_wr,

    // communicate with insCache
    input wire ins_fetch_sig, 
    input wire[31:0] ins_addr,
    output reg ins_fetch_done, // done 1
    output reg[95:0] ins_data,  // three_ins
     // what if current addr overflows
    
    // communicate with lsbuffer
    input wire ls_sig,
    input wire ls_wr, // read 0, write 1
    input wire[2:0] len,
    input wire[31:0] ls_addr,
    input wire[31:0] store_val,
    output reg ls_done, // done 1 
    output reg[31:0] ls_data
    );

    parameter EASE = 2'b00;
    parameter LOAD = 2'b01;
    parameter STORE = 2'b10;
    parameter INFET = 2'b11;
    reg[1:0] state; // 00 at ease, 01 load, 10, store, 11 ins_fetch  
    reg[31:0] cur_addr;
    reg[3:0] len_need_done;
    reg[3:0] len_done;
    always @(posedge clk) begin
        if (rst) begin
            
        end 
        else if (!rdy) begin
            
        end 
        else begin
            case (state) 
                EASE: begin
                    if (ins_fetch_sig) begin
                        state <= INFET;
                        ls_done <= 0;
                        ins_fetch_done <= 0;
                        
                        len_need_done <= 4'b1100; // 12 * 8 = 32 * 3;
                        len_done <= 0;
                        cur_addr <= ins_addr + 1;
                        
                        mem_en <= 1;
                        mem_wr <= 0;
                        mem_addr <= ins_addr;
                        
                    end else if (ls_sig) begin
                        if (ls_wr) begin
                            state <= STORE;
                            ls_done <= 0;
                            ins_fetch_done <= 0;
                            
                            cur_addr <= ls_addr + 1;
                            len_done <= 0;
                            len_need_done <= {1'b0,len}

                            mem_en <= 1;
                            mem_wr <= 1;
                            mem_addr <= ls_addr;
                            mem_out <= store_val[7:0];
                        end
                        else begin
                            state <= LOAD;
                            
                            ls_done <= 0;
                            ins_fetch_done <= 0;
                            
                            cur_addr <= ls_addr + 1;
                            len_done <= 0; 
                            len_need_done <= {1'b0, len}

                            mem_en <= 1;
                            mem_wr <= 0;
                            mem_addr <= ls_addr; 
                        end
                    end 
                end    
                LOAD: begin
                    case (len_done) 
                        0: ls_data[7:0] <= mem_din;  
                        1: ls_data[15:8] <= mem_din;
                        2: ls_data[23:16] <= mem_din;
                        3: ls_data[31:24] <= mem_din;
                    endcase
                    if (len_done == len_need_done) begin
                        ls_done <= 1;
                        state <= EASE;
                        mem_en <= 0;
                        
                    end else begin
                        
                    end
                end
                STORE: begin
                    if (cur_addr[17:16] != 2'b11 || !io_buffer_full) begin

                    end   
                end
                INFET: begin

                end
            endcase
        end   
    end
endmodule