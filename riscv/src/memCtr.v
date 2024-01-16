`ifndef memCtr
`define memCtr

module memCtr (
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire io_buffer_full,
    input wire clear,
    
    // communicate with ram or IO
    input wire[7:0] mem_in, 
    output reg[7:0] mem_out,
    output reg[31:0] mem_addr,
    output reg mem_wr, // read 0 write 1

    // communicate with insCache
    input wire ins_fetch_sig, 
    input wire[31:0] ins_addr,
    output reg ins_fetch_done, // done 1
    output reg[63:0] ins_data,  // three_ins
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
    reg[31:0] cur_addr; // the position you need to write val
    reg[3:0] len_need_done; // the target len
    reg[3:0] len_done; // curlen you need to done 
    
    always @(posedge clk) begin
        if (rst) begin
            state <= 2'b00;
            ls_done <= 1'b0;
            ins_fetch_done <= 1'b0;
            mem_wr <= 1'b0;
            mem_addr <= 32'b0; 
        end 
        else if (!rdy) begin
            if (mem_wr) begin
                mem_wr <= 1'b0;
                mem_addr <= 32'b0;            
            end
            ls_done <= 1'b0;
            ins_fetch_done <= 1'b0;
        end 
        else begin
            case (state) 
                EASE: begin
                    ls_done <= 1'b0;
                    ins_fetch_done <= 1'b0;
                    if (!ls_done && !ins_fetch_done) begin
                        if (ls_sig) begin
                            if (ls_wr) begin
                                state <= STORE;
                                mem_addr <= 32'b0;
                                mem_wr <= 1'b0;
                                cur_addr <= ls_addr;
                                len_done <= 4'b0;
                                len_need_done <= {{1'b0}, len};
                            end else if(!clear) begin
                                state <= LOAD;
                                mem_addr <= ls_addr;
                                mem_wr <= 1'b0;
                                len_done <= 4'b0;
                                len_need_done <= {{1'b0}, len};
                                cur_addr <= ls_addr + 1;
                            end
                        end else if (ins_fetch_sig && !clear) begin
                            state <= INFET;
                            mem_addr <= ins_addr;
                            cur_addr <= ins_addr + 1;
                            len_done <= 4'b0;
                            len_need_done <= 4'b1000;
                            mem_wr <= 1'b0; 
                        end
                        // if (ins_fetch_sig && !clear) begin
                        //     state <= INFET;
                        //     mem_addr <= ins_addr;
                        //     cur_addr <= ins_addr + 1;
                        //     len_done <= 4'b0;
                        //     len_need_done <= 4'b1000;
                        //     mem_wr <= 1'b0; 
                        // end else if (ls_sig) begin
                        //     if (ls_wr) begin
                        //         state <= STORE;
                        //         mem_addr <= 0;
                        //         mem_wr <= 1'b0;
                        //         cur_addr <= ls_addr;
                        //         len_done <= 4'b0;
                        //         len_need_done <= {{1'b0}, len};
                        //     end else if(!clear) begin
                        //         state <= LOAD;
                        //         mem_addr <= ls_addr;
                        //         mem_wr <= 1'b0;
                        //         len_done <= 4'b0;
                        //         len_need_done <= {{1'b0}, len};
                        //         cur_addr <= ls_addr + 1;
                        //     end
                        // end
                    end else begin
                        mem_wr <= 1'b0;
                        mem_addr <= 32'b0;
                    end
                end    
                INFET: begin
                    if (!clear) begin                            
                        case (len_done)
                            4'b0001: ins_data[7 : 0] <= mem_in; 
                            4'b0010: ins_data[15 : 8] <= mem_in; 
                            4'b0011: ins_data[23 : 16] <= mem_in;
                            4'b0100: ins_data[31 : 24] <= mem_in;
                            4'b0101: ins_data[39 : 32] <= mem_in;
                            4'b0110: ins_data[47 : 40] <= mem_in;
                            4'b0111: ins_data[55 : 48] <= mem_in;
                            4'b1000: ins_data[63 : 56] <= mem_in;
                        endcase
                        if (len_done == len_need_done) begin
                            state <= EASE;
                            ins_fetch_done <= 1'b1;
                        end else begin
                            if (len_done + 1 == len_need_done) mem_addr <= 32'b0;
                            else begin
                                mem_addr <= cur_addr;
                                cur_addr <= cur_addr + 1;
                            end
                            len_done <= len_done + 1;
                        end
                    end else begin
                        state <= EASE;
                        mem_wr <= 1'b0;
                        mem_addr <= 32'b0;
                    end
                end
                LOAD: begin
                    if (!clear) begin
                        case (len_done)
                            4'b0001: ls_data[7 : 0] <= mem_in;
                            4'b0010: ls_data[15 : 8] <= mem_in;
                            4'b0011: ls_data[23 : 16] <= mem_in;
                            4'b0100: ls_data[31 : 24] <= mem_in; 
                        endcase
                        if (len_done == len_need_done) begin
                            state <= EASE;
                            ls_done <= 1'b1;    
                        end else begin
                            if (len_done + 1 == len_need_done) mem_addr <= 32'b0;
                            else begin
                                mem_addr <= cur_addr;
                                cur_addr <= cur_addr + 1;
                            end
                            len_done <= len_done + 1;
                        end
                    end else begin
                        state <= EASE;
                        mem_wr <= 1'b0;
                        mem_addr <= 32'b0;
                    end
                end
                STORE: begin
                    if (!io_buffer_full || cur_addr[17 : 16] != 2'b11) begin
                        mem_wr <= 1'b1;
                        case (len_done) 
                            4'b0000: mem_out <= store_val[7 : 0];
                            4'b0001: mem_out <= store_val[15 : 8];
                            4'b0010: mem_out <= store_val[23 : 16];
                            4'b0011: mem_out <= store_val[31 : 24];
                        endcase
                        if (len_done + 1 == len_need_done) begin
                            state <= EASE;
                            ls_done <= 1'b1;
                        end
                        mem_addr <= cur_addr;
                        cur_addr <= cur_addr + 1;
                        len_done <= len_done + 1;
                    end else begin
                        mem_wr <= 1'b0;
                        mem_addr <= 32'b0;
                    end 
                end
            endcase
        end   
    end
endmodule
`endif