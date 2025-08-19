//SystemVerilog
// IEEE 1364-2005 Verilog standard
module HammingShift #(parameter DATA_BITS=4) (
    input clk, sin,
    output reg [DATA_BITS+2:0] encoded // 4数据位 + 3校验位
);
    // 使用泰勒级数展开计算奇偶位
    reg [2:0] parity_accum;
    wire [2:0] next_parity;
    // 为高扇出信号添加缓冲寄存器
    reg [2:0] next_parity_buf1, next_parity_buf2;
    reg [DATA_BITS-1:0] encoded_data_buf;
    reg sin_buf1, sin_buf2;
    
    // 泰勒级数展开近似计算逻辑
    function [2:0] taylor_parity;
        input [DATA_BITS-1:0] data;
        input sin_bit;
        reg [7:0] x, term1, term2;
        reg [7:0] term1_buf1, term1_buf2;
        reg [7:0] term2_buf1, term2_buf2;
        reg [7:0] x_buf1, x_buf2;
        begin
            // 将数据和输入位组合成计算基础
            x = {4'b0, data[3:0]};
            if (sin_bit) x = x + 8'd1;
            
            // 一阶泰勒展开项 - 使用缓冲变量减少扇出负载
            x_buf1 = x;
            x_buf2 = x;
            
            term1 = x_buf1 & 8'h55; // 提取偶数位
            term2 = (x_buf2 & 8'hAA) >> 1; // 提取奇数位
            
            // 为高扇出term1和term2创建缓冲
            term1_buf1 = term1;
            term1_buf2 = term1;
            term2_buf1 = term2;
            term2_buf2 = term2;
            
            // 计算p0 - 使用缓冲减少扇出负载
            taylor_parity[0] = (term1[1] ^ term2[1]) ^ (term1_buf1[2] ^ term2_buf1[2]) ^ (term1_buf2[3] ^ term2_buf2[3]);
            
            // 计算p1 - 使用缓冲减少扇出负载
            taylor_parity[1] = (term1[0] ^ term2[0]) ^ (term1[2] ^ term2[2]) ^ (term1_buf1[3] ^ term2_buf1[3]);
            
            // 计算p2 - 使用缓冲减少扇出负载
            taylor_parity[2] = (term1[0] ^ term2[0]) ^ (term1_buf1[1] ^ term2_buf1[1]) ^ (term1_buf2[3] ^ term2_buf2[3]);
        end
    endfunction
    
    // 计算下一个奇偶位状态
    assign next_parity = taylor_parity(encoded_data_buf, sin_buf1);
    
    // 添加中间寄存器缓冲，减少扇出负载，提高时序性能
    always @(posedge clk) begin
        // 为高扇出信号添加缓冲
        encoded_data_buf <= encoded[3:0];
        sin_buf1 <= sin;
        sin_buf2 <= sin_buf1;
        
        // 缓冲next_parity信号，减少扇出
        next_parity_buf1 <= next_parity;
        next_parity_buf2 <= next_parity_buf1;
        
        // 移位操作
        encoded <= {encoded[DATA_BITS+1:0], sin_buf2};
        
        // 更新奇偶位 - 使用缓冲的奇偶位减少扇出负载
        encoded[4] <= next_parity_buf2[0];
        encoded[5] <= next_parity_buf2[1];
        encoded[6] <= next_parity_buf2[2];
    end
endmodule