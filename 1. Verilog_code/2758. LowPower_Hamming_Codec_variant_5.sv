//SystemVerilog
module LowPower_Hamming_Codec(
    input clk,
    input power_save_en,
    input [15:0] data_in,
    output reg [15:0] data_out
);
    // 使用时钟使能代替门控时钟，改善时序性能
    reg clk_en;
    reg [15:0] encoded_data;
    
    // 使能逻辑
    always @(posedge clk) begin
        clk_en <= ~power_save_en;
    end
    
    // Hamming编码实现
    always @(*) begin
        encoded_data = HammingEncode(data_in);
    end
    
    // 寄存器更新
    always @(posedge clk) begin
        if (clk_en)
            data_out <= encoded_data;
    end
    
    // Hamming编码函数优化实现
    function [15:0] HammingEncode;
        input [15:0] data;
        reg [4:0] parity;
        begin
            // 计算奇偶校验位
            parity[0] = ^(data & 16'b1010_1010_1010_1010);
            parity[1] = ^(data & 16'b1100_1100_1100_1100);
            parity[2] = ^(data & 16'b1111_0000_1111_0000);
            parity[3] = ^(data & 16'b1111_1111_0000_0000);
            parity[4] = ^{data, parity[3:0]};
            
            // 组成返回数据
            HammingEncode = {data[15:5], parity[4], data[4:1], parity[3:0]};
        end
    endfunction
endmodule