//SystemVerilog
module pcs_64b66b_enc (
    input clk,
    input rst,
    input [63:0] tx_data,
    input tx_valid,
    output reg [65:0] encoded_data,
    output reg enc_valid
);
    localparam SYNC_HEADER = 2'b10;
    
    // 减少为两个流水线阶段
    reg [57:0] scrambler_state;
    reg [63:0] tx_data_stage1;
    reg tx_valid_stage1;
    
    // 混淆多项式
    wire [57:0] scrambler_poly = 58'h3F_FFFF_FFFF_FFFF;
    
    // LFSR操作
    wire next_bit = scrambler_state[57] ^ scrambler_state[38];
    
    // 第一级流水线 - 处理输入和LFSR状态更新
    always @(posedge clk) begin
        if (rst) begin
            scrambler_state <= 58'h1FF;
            tx_data_stage1 <= 64'h0;
            tx_valid_stage1 <= 1'b0;
        end else begin
            // 保存输入数据和有效信号
            tx_data_stage1 <= tx_data;
            tx_valid_stage1 <= tx_valid;
            
            // 更新LFSR状态
            if (tx_valid) begin
                scrambler_state <= {scrambler_state[56:0], next_bit};
            end
        end
    end
    
    // 第二级流水线 - 同时处理高32位和低32位数据的加扰和最终输出
    always @(posedge clk) begin
        if (rst) begin
            encoded_data <= 66'h0;
            enc_valid <= 1'b0;
        end else begin
            if (tx_valid_stage1) begin
                // 高32位数据的加扰 (32-63)
                encoded_data[65:34] <= {
                    tx_data_stage1[63] ^ (scrambler_state[52] ^ scrambler_state[33]) ^ (scrambler_state[33] ^ scrambler_state[14]),
                    tx_data_stage1[62] ^ (scrambler_state[53] ^ scrambler_state[34]) ^ (scrambler_state[34] ^ scrambler_state[15]),
                    tx_data_stage1[61] ^ (scrambler_state[54] ^ scrambler_state[35]) ^ (scrambler_state[35] ^ scrambler_state[16]),
                    tx_data_stage1[60] ^ (scrambler_state[55] ^ scrambler_state[36]) ^ (scrambler_state[36] ^ scrambler_state[17]),
                    tx_data_stage1[59] ^ (scrambler_state[56] ^ scrambler_state[37]) ^ (scrambler_state[37] ^ scrambler_state[18]),
                    tx_data_stage1[58] ^ next_bit ^ (scrambler_state[38] ^ scrambler_state[19]),
                    tx_data_stage1[57] ^ scrambler_state[0] ^ (scrambler_state[39] ^ scrambler_state[20]),
                    tx_data_stage1[56] ^ scrambler_state[1] ^ (scrambler_state[40] ^ scrambler_state[21]),
                    tx_data_stage1[55] ^ scrambler_state[2] ^ (scrambler_state[41] ^ scrambler_state[22]),
                    tx_data_stage1[54] ^ scrambler_state[3] ^ (scrambler_state[42] ^ scrambler_state[23]),
                    tx_data_stage1[53] ^ scrambler_state[4] ^ (scrambler_state[43] ^ scrambler_state[24]),
                    tx_data_stage1[52] ^ scrambler_state[5] ^ (scrambler_state[44] ^ scrambler_state[25]),
                    tx_data_stage1[51] ^ scrambler_state[6] ^ (scrambler_state[45] ^ scrambler_state[26]),
                    tx_data_stage1[50] ^ scrambler_state[7] ^ (scrambler_state[46] ^ scrambler_state[27]),
                    tx_data_stage1[49] ^ scrambler_state[8] ^ (scrambler_state[47] ^ scrambler_state[28]),
                    tx_data_stage1[48] ^ scrambler_state[9] ^ (scrambler_state[48] ^ scrambler_state[29]),
                    tx_data_stage1[47] ^ scrambler_state[10] ^ (scrambler_state[49] ^ scrambler_state[30]),
                    tx_data_stage1[46] ^ scrambler_state[11] ^ (scrambler_state[50] ^ scrambler_state[31]),
                    tx_data_stage1[45] ^ scrambler_state[12] ^ (scrambler_state[51] ^ scrambler_state[32]),
                    tx_data_stage1[44] ^ scrambler_state[13] ^ (scrambler_state[52] ^ scrambler_state[33]),
                    tx_data_stage1[43] ^ scrambler_state[14] ^ (scrambler_state[53] ^ scrambler_state[34]),
                    tx_data_stage1[42] ^ scrambler_state[15] ^ (scrambler_state[54] ^ scrambler_state[35]),
                    tx_data_stage1[41] ^ scrambler_state[16] ^ (scrambler_state[55] ^ scrambler_state[36]),
                    tx_data_stage1[40] ^ scrambler_state[17] ^ (scrambler_state[56] ^ scrambler_state[37]),
                    tx_data_stage1[39] ^ scrambler_state[18] ^ next_bit,
                    tx_data_stage1[38] ^ scrambler_state[19] ^ scrambler_state[0],
                    tx_data_stage1[37] ^ scrambler_state[20] ^ scrambler_state[1],
                    tx_data_stage1[36] ^ scrambler_state[21] ^ scrambler_state[2],
                    tx_data_stage1[35] ^ scrambler_state[22] ^ scrambler_state[3],
                    tx_data_stage1[34] ^ scrambler_state[23] ^ scrambler_state[4],
                    tx_data_stage1[33] ^ scrambler_state[24] ^ scrambler_state[5],
                    tx_data_stage1[32] ^ scrambler_state[25] ^ scrambler_state[6]
                };
                
                // 低32位数据的加扰 (0-31)
                encoded_data[33:2] <= {
                    tx_data_stage1[31] ^ (scrambler_state[26] ^ scrambler_state[7]),
                    tx_data_stage1[30] ^ (scrambler_state[27] ^ scrambler_state[8]),
                    tx_data_stage1[29] ^ (scrambler_state[28] ^ scrambler_state[9]),
                    tx_data_stage1[28] ^ (scrambler_state[29] ^ scrambler_state[10]),
                    tx_data_stage1[27] ^ (scrambler_state[30] ^ scrambler_state[11]),
                    tx_data_stage1[26] ^ (scrambler_state[31] ^ scrambler_state[12]),
                    tx_data_stage1[25] ^ (scrambler_state[32] ^ scrambler_state[13]),
                    tx_data_stage1[24] ^ (scrambler_state[33] ^ scrambler_state[14]),
                    tx_data_stage1[23] ^ (scrambler_state[34] ^ scrambler_state[15]),
                    tx_data_stage1[22] ^ (scrambler_state[35] ^ scrambler_state[16]),
                    tx_data_stage1[21] ^ (scrambler_state[36] ^ scrambler_state[17]),
                    tx_data_stage1[20] ^ (scrambler_state[37] ^ scrambler_state[18]),
                    tx_data_stage1[19] ^ (scrambler_state[38] ^ scrambler_state[19]),
                    tx_data_stage1[18] ^ (scrambler_state[39] ^ scrambler_state[20]),
                    tx_data_stage1[17] ^ (scrambler_state[40] ^ scrambler_state[21]),
                    tx_data_stage1[16] ^ (scrambler_state[41] ^ scrambler_state[22]),
                    tx_data_stage1[15] ^ (scrambler_state[42] ^ scrambler_state[23]),
                    tx_data_stage1[14] ^ (scrambler_state[43] ^ scrambler_state[24]),
                    tx_data_stage1[13] ^ (scrambler_state[44] ^ scrambler_state[25]),
                    tx_data_stage1[12] ^ (scrambler_state[45] ^ scrambler_state[26]),
                    tx_data_stage1[11] ^ (scrambler_state[46] ^ scrambler_state[27]),
                    tx_data_stage1[10] ^ (scrambler_state[47] ^ scrambler_state[28]),
                    tx_data_stage1[9] ^ (scrambler_state[48] ^ scrambler_state[29]),
                    tx_data_stage1[8] ^ (scrambler_state[49] ^ scrambler_state[30]),
                    tx_data_stage1[7] ^ (scrambler_state[50] ^ scrambler_state[31]),
                    tx_data_stage1[6] ^ (scrambler_state[51] ^ scrambler_state[32]),
                    tx_data_stage1[5] ^ (scrambler_state[52] ^ scrambler_state[33]),
                    tx_data_stage1[4] ^ (scrambler_state[53] ^ scrambler_state[34]),
                    tx_data_stage1[3] ^ (scrambler_state[54] ^ scrambler_state[35]),
                    tx_data_stage1[2] ^ (scrambler_state[55] ^ scrambler_state[36]),
                    tx_data_stage1[1] ^ (scrambler_state[56] ^ scrambler_state[37]),
                    tx_data_stage1[0] ^ scrambler_state[57]
                };
                
                // 添加同步头
                encoded_data[1:0] <= SYNC_HEADER;
                enc_valid <= 1'b1;
            end else begin
                enc_valid <= 1'b0;
            end
        end
    end
endmodule