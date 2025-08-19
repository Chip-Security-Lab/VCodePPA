//SystemVerilog
module Reconfig_Hamming_Codec(
    input clk,
    input [1:0] config_mode,
    input [31:0] data_in,
    output reg [31:0] data_out
);
    // 中间变量定义
    reg parity_bit;
    reg [3:0] check_bits;
    
    // (7,4)码 计算逻辑
    wire parity_7_4 = ^data_in[3:0];
    wire check_bit1_7_4 = data_in[3]^data_in[2];
    wire check_bit2_7_4 = data_in[3]^data_in[1];
    
    // (15,11)码 计算逻辑
    wire parity_15_11 = ^data_in[10:0];
    wire check_bit1_15_11 = data_in[10]^data_in[9]^data_in[6]^data_in[5]^data_in[3]^data_in[0];
    wire check_bit2_15_11 = data_in[10]^data_in[8]^data_in[7]^data_in[5]^data_in[4]^data_in[1];
    wire check_bit3_15_11 = data_in[9]^data_in[8]^data_in[7]^data_in[3]^data_in[2]^data_in[0];
    
    // (31,26)码 计算逻辑
    wire parity_31_26 = ^data_in[25:0];
    
    wire [17:0] group1_31_26 = {data_in[25:20], data_in[15:10], data_in[5:0]};
    wire check_bit1_31_26 = ^group1_31_26;
    
    wire [20:0] group2_31_26 = {data_in[25:16], data_in[10:1]};
    wire check_bit2_31_26 = ^group2_31_26;
    
    wire [15:0] group3_31_26 = {data_in[25:21], data_in[15:11], data_in[5:1]};
    wire check_bit3_31_26 = ^group3_31_26;
    
    wire [15:0] group4_31_26 = {data_in[20:16], data_in[10:6], data_in[0]};
    wire check_bit4_31_26 = ^group4_31_26;
    
    wire non_zero_check_31_26 = |data_in[31:26];
    
    // SECDED 计算逻辑
    wire parity_secded = ^data_in[30:0];
    
    always @(posedge clk) begin
        case(config_mode)
            2'b00: begin // (7,4)码
                data_out[3:0] <= data_in[3:0];                       // 数据位
                data_out[4] <= parity_7_4;                           // 奇偶校验位
                data_out[5] <= check_bit1_7_4;                       // 校验位1
                data_out[6] <= check_bit2_7_4;                       // 校验位2
                data_out[31:7] <= data_in[31:4];                     // 剩余位保持不变
            end
            
            2'b01: begin // (15,11)码
                data_out[10:0] <= data_in[10:0];                     // 数据位
                data_out[11] <= parity_15_11;                        // 奇偶校验位
                data_out[12] <= check_bit1_15_11;                    // 校验位1
                data_out[13] <= check_bit2_15_11;                    // 校验位2
                data_out[14] <= check_bit3_15_11;                    // 校验位3
                data_out[31:15] <= data_in[31:11];                   // 剩余位保持不变
            end
            
            2'b10: begin // (31,26)码
                data_out[25:0] <= data_in[25:0];                     // 数据位
                data_out[26] <= parity_31_26;                        // 奇偶校验位
                data_out[27] <= check_bit1_31_26;                    // 校验位1
                data_out[28] <= check_bit2_31_26;                    // 校验位2
                data_out[29] <= check_bit3_31_26;                    // 校验位3
                data_out[30] <= check_bit4_31_26;                    // 校验位4
                data_out[31] <= non_zero_check_31_26;                // 非零检查
            end
            
            2'b11: begin // SECDED
                data_out[30:0] <= data_in[30:0];                     // 数据位
                data_out[31] <= parity_secded;                       // 奇偶校验位
            end
        endcase
    end
endmodule