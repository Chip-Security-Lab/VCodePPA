//SystemVerilog
// SystemVerilog
module ClkNor(
    input clk,
    input a,
    input b, 
    output reg y
);
    reg a_nor_b;
    
    always @(posedge clk) begin
        // 计算中间结果
        a_nor_b = ~a & ~b;
        
        // 基于中间结果确定输出
        if (a_nor_b)
            y <= 1'b1;
        else
            y <= 1'b0;
    end
endmodule