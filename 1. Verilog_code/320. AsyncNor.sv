module AsyncNor(input clk, rst, a, b, output reg y);
    always @(posedge clk, posedge rst) 
        y <= rst ? 0 : ~(a | b); // 复位优先
endmodule