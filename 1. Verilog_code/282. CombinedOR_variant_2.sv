//SystemVerilog
module CombinedOR(
    input [1:0] sel,
    input [3:0] a, b, c, d,
    output reg [3:0] res
);
    wire [3:0] ab_result, cd_result;
    
    // 预计算组合逻辑
    assign ab_result = a | b;
    assign cd_result = c | d;
    
    // 根据选择信号合并结果
    always @(*) begin
        res = 4'b0000;
        
        if (sel[1])
            res = res | ab_result;
            
        if (sel[0])
            res = res | cd_result;
    end
endmodule