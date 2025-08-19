//SystemVerilog
module Reconfig_Hamming_Codec(
    input clk,
    input [1:0] config_mode,
    input [31:0] data_in,
    output reg [31:0] data_out
);
    // 定义中间变量以提高可读性和性能
    reg [3:0] parity_7_4;
    reg [3:0] parity_15_11;
    reg [4:0] parity_31_26;
    reg parity_secded;
    
    // 对各个模式的奇偶校验位进行预计算
    always @(*) begin
        // (7,4)码的奇偶校验位计算
        parity_7_4[0] = data_in[3] ^ data_in[2] ^ data_in[1] ^ data_in[0];
        parity_7_4[1] = data_in[3] ^ data_in[2];
        parity_7_4[2] = data_in[3] ^ data_in[1];
        parity_7_4[3] = 1'b0; // 未使用
        
        // (15,11)码的奇偶校验位计算
        parity_15_11[0] = ^data_in[10:0];
        parity_15_11[1] = data_in[10] ^ data_in[9] ^ data_in[6] ^ data_in[5] ^ data_in[3] ^ data_in[0];
        parity_15_11[2] = data_in[10] ^ data_in[8] ^ data_in[7] ^ data_in[5] ^ data_in[4] ^ data_in[1];
        parity_15_11[3] = data_in[9] ^ data_in[8] ^ data_in[7] ^ data_in[3] ^ data_in[2] ^ data_in[0];
        
        // (31,26)码的奇偶校验位计算 - 简化表达式
        parity_31_26[0] = ^data_in[25:0];
        parity_31_26[1] = ^{data_in[25:20], data_in[15:10], data_in[5:0]};
        parity_31_26[2] = ^{data_in[25:16], data_in[10:1]};
        parity_31_26[3] = ^{data_in[25:21], data_in[15:11], data_in[5:1]};
        parity_31_26[4] = ^{data_in[20:16], data_in[10:6], data_in[0]};
        
        // SECDED的奇偶校验位计算
        parity_secded = ^data_in[30:0];
    end
    
    // 根据配置模式选择输出数据
    always @(posedge clk) begin
        case(config_mode)
            2'b00: begin // (7,4)码
                data_out[3:0] <= data_in[3:0];
                data_out[6:4] <= parity_7_4[2:0];
                data_out[31:7] <= data_in[31:4];
            end
            
            2'b01: begin // (15,11)码
                data_out[10:0] <= data_in[10:0];
                data_out[14:11] <= parity_15_11[3:0];
                data_out[31:15] <= data_in[31:11];
            end
            
            2'b10: begin // (31,26)码
                data_out[25:0] <= data_in[25:0];
                data_out[30:26] <= parity_31_26[4:0];
                data_out[31] <= |data_in[31:26]; // 使用或运算替代不等于0的比较
            end
            
            2'b11: begin // SECDED
                data_out[30:0] <= data_in[30:0];
                data_out[31] <= parity_secded;
            end
        endcase
    end
endmodule