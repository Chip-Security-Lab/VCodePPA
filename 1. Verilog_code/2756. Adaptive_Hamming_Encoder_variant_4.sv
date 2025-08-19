//SystemVerilog
module Adaptive_Hamming_Encoder(
    input clk,
    input [7:0] data_in,
    output reg [11:0] adaptive_code,
    output reg [2:0] parity_bits_used
);
    // 展开的 count_ones 函数
    function [2:0] count_ones;
        input [7:0] data;
        reg [2:0] count;
        begin
            count = 0;
            // 展开的for循环
            if(data[0]) count = count + 1;
            if(data[1]) count = count + 1;
            if(data[2]) count = count + 1;
            if(data[3]) count = count + 1;
            if(data[4]) count = count + 1;
            if(data[5]) count = count + 1;
            if(data[6]) count = count + 1;
            if(data[7]) count = count + 1;
            count_ones = count;
        end
    endfunction
    
    // 第一级流水线寄存器
    reg [7:0] data_pipe1;
    reg [2:0] ones_count_pipe1;
    
    // 第二级流水线寄存器
    reg [7:0] data_pipe2;
    reg [2:0] ones_count_pipe2;
    reg parity_bit_p1; // 用于高密度情况的第一个奇偶校验位计算
    
    // 组合逻辑
    wire [2:0] ones_count = count_ones(data_in);
    wire parity_all = ^data_in; // 提前计算全部位的奇偶校验
    
    always @(posedge clk) begin
        // 第一级流水线
        data_pipe1 <= data_in;
        ones_count_pipe1 <= ones_count;
        
        // 第二级流水线
        data_pipe2 <= data_pipe1;
        ones_count_pipe2 <= ones_count_pipe1;
        parity_bit_p1 <= parity_all; // 存储第一个奇偶校验位
        
        // 最终输出逻辑
        case(ones_count_pipe2)
            3'd0, 3'd1, 3'd2: begin // 低密度使用(8,4)码
                adaptive_code[10:8] <= data_pipe2[7:4];
                adaptive_code[7] <= ^{data_pipe2[7:4], data_pipe2[3:0]};
                adaptive_code[6:0] <= {data_pipe2[3:0], 3'b0};
                parity_bits_used <= 3'd4;
            end
            default: begin // 高密度使用(12,8)码
                adaptive_code[11] <= parity_bit_p1; // 使用已计算的奇偶校验位
                adaptive_code[10:3] <= data_pipe2;
                adaptive_code[2] <= ^{data_pipe2[7:5], data_pipe2[3:1]};
                adaptive_code[1] <= ^{data_pipe2[4:2], data_pipe2[0]};
                adaptive_code[0] <= ^{data_pipe2[7:4], data_pipe2[3:0]};
                parity_bits_used <= 3'd3;
            end
        endcase
    end
endmodule