module regFile(clk, rdSig, rtSig, regId, modifydata, readData);
    input wire clk;
    input wire rdSig;
    input wire rtSig;
    input wire regId;
    input wire[31:0] modifyData;
    output reg[31:0] readData;  
    reg[31:0] registers[31:0];   
endmodule