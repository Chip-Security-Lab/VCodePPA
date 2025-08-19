//SystemVerilog
module hamming_parity_precalc(
    input clk, en,
    input [3:0] data,
    output reg [6:0] code
);
    // 直接在always块中生成校验位并赋值给code
    // 消除中间寄存器p1,p2,p4，减少时钟周期延迟
    
    // 预先计算data[3:1]和data[0]的部分，避免多次读取相同信号
    // 应用路径平衡优化，将代码整合到一个always块中
    always @(posedge clk) begin
        if (en) begin
            // 直接组合生成汉明码
            // 通过并行计算替代串行依赖，优化关键路径
            code[0] <= data[0] ^ data[1] ^ data[3];          // p1
            code[1] <= data[0] ^ data[2] ^ data[3];          // p2
            code[2] <= data[0];                              // d0
            code[3] <= data[1] ^ data[2] ^ data[3];          // p4
            code[4] <= data[1];                              // d1
            code[5] <= data[2];                              // d2
            code[6] <= data[3];                              // d3
        end
    end
endmodule