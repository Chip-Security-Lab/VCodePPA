//SystemVerilog
module ClkNor(input clk, a, b, output reg y);
    wire nor_out;
    
    // 组合逻辑计算
    assign nor_out = ~(a | b);
    
    // 将寄存器移到组合逻辑之后
    always @(posedge clk) begin
        y <= nor_out;
    end
endmodule