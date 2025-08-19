//SystemVerilog
module LowPower_Hamming_Codec(
    input clk,
    input power_save_en,
    input [15:0] data_in,
    output reg [15:0] data_out
);
    // 使用专用的时钟门控单元替代简单的AND门
    // 这样可以避免毛刺并提高功耗效率
    wire gated_clk;
    
    // 时钟门控单元实例化
    CLKGATE clock_gate_inst (
        .CLK(clk),
        .EN(~power_save_en),
        .GCLK(gated_clk)
    );
    
    // 直接将输出赋值给data_out，减少中间寄存器
    always @(posedge gated_clk) begin
        data_out <= HammingEncode(data_in);
    end
    
    // 汉明编码实现
    function [15:0] HammingEncode;
        input [15:0] data;
        reg [4:0] parity;
        begin
            // 计算奇偶校验位
            parity[0] = ^(data & 16'b1010_1010_1010_1010);
            parity[1] = ^(data & 16'b1100_1100_1100_1100);
            parity[2] = ^(data & 16'b1111_0000_1111_0000);
            parity[3] = ^(data & 16'b1111_1111_0000_0000);
            parity[4] = ^{data, parity[3:0]}; // 总校验位
            
            // 返回带有校验位的编码数据
            HammingEncode = {parity[4], data[15:11], parity[3], 
                            data[10:4], parity[2], data[3:1], 
                            parity[1], data[0], parity[0]};
        end
    endfunction
endmodule

// 时钟门控单元模块
module CLKGATE(
    input CLK,
    input EN,
    output GCLK
);
    reg latch_en;
    
    // 使用锁存器实现标准时钟门控单元
    always @(*) begin
        if (~CLK)
            latch_en <= EN;
    end
    
    // 生成无毛刺的门控时钟
    assign GCLK = CLK & latch_en;
endmodule