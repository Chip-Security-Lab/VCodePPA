//SystemVerilog
module Adaptive_Hamming_Encoder(
    input clk,
    input [7:0] data_in,
    output reg [11:0] adaptive_code,
    output reg [2:0] parity_bits_used
);
    // 带状进位加法器实现的计数函数
    function [2:0] count_ones;
        input [7:0] data;
        reg [7:0] stage1_sum;
        reg [3:0] stage2_sum;
        reg [2:0] count;
        begin
            // 第一级: 2位一组
            stage1_sum[0] = data[0] ^ data[1];
            stage1_sum[1] = data[0] & data[1];
            stage1_sum[2] = data[2] ^ data[3];
            stage1_sum[3] = data[2] & data[3];
            stage1_sum[4] = data[4] ^ data[5];
            stage1_sum[5] = data[4] & data[5];
            stage1_sum[6] = data[6] ^ data[7];
            stage1_sum[7] = data[6] & data[7];
            
            // 第二级: 将第一级结果合并
            stage2_sum[0] = stage1_sum[0] ^ stage1_sum[2];
            stage2_sum[1] = (stage1_sum[0] & stage1_sum[2]) | (stage1_sum[1] ^ stage1_sum[3]);
            stage2_sum[2] = stage1_sum[1] & stage1_sum[3];
            
            stage2_sum[3] = stage1_sum[4] ^ stage1_sum[6];
            
            // 最终计算
            count[0] = stage2_sum[0] ^ stage2_sum[3];
            count[1] = (stage2_sum[0] & stage2_sum[3]) | (stage2_sum[1] ^ (stage1_sum[5] ^ stage1_sum[7]));
            count[2] = stage2_sum[2] | ((stage2_sum[1] & (stage1_sum[5] ^ stage1_sum[7])) | (stage1_sum[5] & stage1_sum[7]));
            
            count_ones = count;
        end
    endfunction
    
    wire [2:0] ones_count = count_ones(data_in);
    
    always @(posedge clk) begin
        case(ones_count)
            3'd0, 3'd1, 3'd2: begin // 低密度使用(8,4)码
                adaptive_code[10:8] <= data_in[7:4];
                adaptive_code[7] <= ^{data_in[7:4], data_in[3:0]};
                adaptive_code[6:0] <= {data_in[3:0], 3'b0};
                parity_bits_used <= 3'd4;
            end
            default: begin // 高密度使用(12,8)码
                adaptive_code[11] <= ^data_in;
                adaptive_code[10:3] <= data_in;
                adaptive_code[2] <= ^{data_in[7:5], data_in[3:1]};
                adaptive_code[1] <= ^{data_in[4:2], data_in[0]};
                adaptive_code[0] <= ^{data_in[7:4], data_in[3:0]};
                parity_bits_used <= 3'd3;
            end
        endcase
    end
endmodule