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
    
    // 输入数据和有效信号的流水线寄存
    reg [63:0] tx_data_reg;
    reg tx_valid_reg;
    reg [57:0] scrambler_state;
    
    // 中间流水线寄存器，用于切割关键路径
    reg [31:0] scrambled_data_stage1_low;
    reg [31:0] scrambled_data_stage1_high;
    reg tx_valid_stage1;
    
    // 组合逻辑通过线网声明
    wire [63:0] scrambled_data;
    wire next_bit = scrambler_state[57] ^ scrambler_state[38];
    
    // 第一阶段组合逻辑计算的中间结果
    wire [31:0] scrambled_data_low;
    wire [31:0] scrambled_data_high;
    
    // 输入数据寄存
    always @(posedge clk) begin
        if (rst) begin
            tx_data_reg <= 64'h0;
            tx_valid_reg <= 1'b0;
        end else begin
            tx_data_reg <= tx_data;
            tx_valid_reg <= tx_valid;
        end
    end
    
    // 移位寄存器逻辑
    always @(posedge clk) begin
        if (rst) begin
            scrambler_state <= 58'h1FF;
        end else if (tx_valid_reg) begin
            scrambler_state <= {scrambler_state[56:0], next_bit};
        end
    end
    
    // 组合逻辑部分 - 低32位计算
    assign scrambled_data_low[0] = tx_data_reg[0] ^ scrambler_state[57];
    assign scrambled_data_low[1] = tx_data_reg[1] ^ (scrambler_state[56] ^ (scrambler_state[37] ^ scrambler_state[57]));
    assign scrambled_data_low[2] = tx_data_reg[2] ^ (scrambler_state[55] ^ (scrambler_state[36] ^ (scrambler_state[56] ^ scrambler_state[37])));
    assign scrambled_data_low[3] = tx_data_reg[3] ^ (scrambler_state[54] ^ (scrambler_state[35] ^ (scrambler_state[55] ^ scrambler_state[36])));
    assign scrambled_data_low[4] = tx_data_reg[4] ^ (scrambler_state[53] ^ (scrambler_state[34] ^ (scrambler_state[54] ^ scrambler_state[35])));
    assign scrambled_data_low[5] = tx_data_reg[5] ^ (scrambler_state[52] ^ (scrambler_state[33] ^ (scrambler_state[53] ^ scrambler_state[34])));
    assign scrambled_data_low[6] = tx_data_reg[6] ^ (scrambler_state[51] ^ (scrambler_state[32] ^ (scrambler_state[52] ^ scrambler_state[33])));
    assign scrambled_data_low[7] = tx_data_reg[7] ^ (scrambler_state[50] ^ (scrambler_state[31] ^ (scrambler_state[51] ^ scrambler_state[32])));
    // 继续计算低32位
    assign scrambled_data_low[8] = tx_data_reg[8] ^ (scrambler_state[49] ^ (scrambler_state[30] ^ (scrambler_state[50] ^ scrambler_state[31])));
    assign scrambled_data_low[9] = tx_data_reg[9] ^ (scrambler_state[48] ^ (scrambler_state[29] ^ (scrambler_state[49] ^ scrambler_state[30])));
    assign scrambled_data_low[10] = tx_data_reg[10] ^ (scrambler_state[47] ^ (scrambler_state[28] ^ (scrambler_state[48] ^ scrambler_state[29])));
    assign scrambled_data_low[11] = tx_data_reg[11] ^ (scrambler_state[46] ^ (scrambler_state[27] ^ (scrambler_state[47] ^ scrambler_state[28])));
    assign scrambled_data_low[12] = tx_data_reg[12] ^ (scrambler_state[45] ^ (scrambler_state[26] ^ (scrambler_state[46] ^ scrambler_state[27])));
    assign scrambled_data_low[13] = tx_data_reg[13] ^ (scrambler_state[44] ^ (scrambler_state[25] ^ (scrambler_state[45] ^ scrambler_state[26])));
    assign scrambled_data_low[14] = tx_data_reg[14] ^ (scrambler_state[43] ^ (scrambler_state[24] ^ (scrambler_state[44] ^ scrambler_state[25])));
    assign scrambled_data_low[15] = tx_data_reg[15] ^ (scrambler_state[42] ^ (scrambler_state[23] ^ (scrambler_state[43] ^ scrambler_state[24])));
    assign scrambled_data_low[16] = tx_data_reg[16] ^ (scrambler_state[41] ^ (scrambler_state[22] ^ (scrambler_state[42] ^ scrambler_state[23])));
    assign scrambled_data_low[17] = tx_data_reg[17] ^ (scrambler_state[40] ^ (scrambler_state[21] ^ (scrambler_state[41] ^ scrambler_state[22])));
    assign scrambled_data_low[18] = tx_data_reg[18] ^ (scrambler_state[39] ^ (scrambler_state[20] ^ (scrambler_state[40] ^ scrambler_state[21])));
    assign scrambled_data_low[19] = tx_data_reg[19] ^ (scrambler_state[38] ^ (scrambler_state[19] ^ (scrambler_state[39] ^ scrambler_state[20])));
    assign scrambled_data_low[20] = tx_data_reg[20] ^ (scrambler_state[37] ^ (scrambler_state[18] ^ (scrambler_state[38] ^ scrambler_state[19])));
    assign scrambled_data_low[21] = tx_data_reg[21] ^ (scrambler_state[36] ^ (scrambler_state[17] ^ (scrambler_state[37] ^ scrambler_state[18])));
    assign scrambled_data_low[22] = tx_data_reg[22] ^ (scrambler_state[35] ^ (scrambler_state[16] ^ (scrambler_state[36] ^ scrambler_state[17])));
    assign scrambled_data_low[23] = tx_data_reg[23] ^ (scrambler_state[34] ^ (scrambler_state[15] ^ (scrambler_state[35] ^ scrambler_state[16])));
    assign scrambled_data_low[24] = tx_data_reg[24] ^ (scrambler_state[33] ^ (scrambler_state[14] ^ (scrambler_state[34] ^ scrambler_state[15])));
    assign scrambled_data_low[25] = tx_data_reg[25] ^ (scrambler_state[32] ^ (scrambler_state[13] ^ (scrambler_state[33] ^ scrambler_state[14])));
    assign scrambled_data_low[26] = tx_data_reg[26] ^ (scrambler_state[31] ^ (scrambler_state[12] ^ (scrambler_state[32] ^ scrambler_state[13])));
    assign scrambled_data_low[27] = tx_data_reg[27] ^ (scrambler_state[30] ^ (scrambler_state[11] ^ (scrambler_state[31] ^ scrambler_state[12])));
    assign scrambled_data_low[28] = tx_data_reg[28] ^ (scrambler_state[29] ^ (scrambler_state[10] ^ (scrambler_state[30] ^ scrambler_state[11])));
    assign scrambled_data_low[29] = tx_data_reg[29] ^ (scrambler_state[28] ^ (scrambler_state[9] ^ (scrambler_state[29] ^ scrambler_state[10])));
    assign scrambled_data_low[30] = tx_data_reg[30] ^ (scrambler_state[27] ^ (scrambler_state[8] ^ (scrambler_state[28] ^ scrambler_state[9])));
    assign scrambled_data_low[31] = tx_data_reg[31] ^ (scrambler_state[26] ^ (scrambler_state[7] ^ (scrambler_state[27] ^ scrambler_state[8])));
    
    // 组合逻辑部分 - 高32位计算
    assign scrambled_data_high[0] = tx_data_reg[32] ^ (scrambler_state[25] ^ (scrambler_state[6] ^ (scrambler_state[26] ^ scrambler_state[7])));
    assign scrambled_data_high[1] = tx_data_reg[33] ^ (scrambler_state[24] ^ (scrambler_state[5] ^ (scrambler_state[25] ^ scrambler_state[6])));
    assign scrambled_data_high[2] = tx_data_reg[34] ^ (scrambler_state[23] ^ (scrambler_state[4] ^ (scrambler_state[24] ^ scrambler_state[5])));
    assign scrambled_data_high[3] = tx_data_reg[35] ^ (scrambler_state[22] ^ (scrambler_state[3] ^ (scrambler_state[23] ^ scrambler_state[4])));
    assign scrambled_data_high[4] = tx_data_reg[36] ^ (scrambler_state[21] ^ (scrambler_state[2] ^ (scrambler_state[22] ^ scrambler_state[3])));
    assign scrambled_data_high[5] = tx_data_reg[37] ^ (scrambler_state[20] ^ (scrambler_state[1] ^ (scrambler_state[21] ^ scrambler_state[2])));
    assign scrambled_data_high[6] = tx_data_reg[38] ^ (scrambler_state[19] ^ (scrambler_state[0] ^ (scrambler_state[20] ^ scrambler_state[1])));
    assign scrambled_data_high[7] = tx_data_reg[39] ^ (scrambler_state[18] ^ (next_bit ^ (scrambler_state[19] ^ scrambler_state[0])));
    // 继续计算高32位
    assign scrambled_data_high[8] = tx_data_reg[40] ^ (scrambler_state[17] ^ (scrambler_state[57] ^ scrambler_state[18]));
    assign scrambled_data_high[9] = tx_data_reg[41] ^ (scrambler_state[16] ^ (scrambler_state[56] ^ scrambler_state[17]));
    assign scrambled_data_high[10] = tx_data_reg[42] ^ (scrambler_state[15] ^ (scrambler_state[55] ^ scrambler_state[16]));
    assign scrambled_data_high[11] = tx_data_reg[43] ^ (scrambler_state[14] ^ (scrambler_state[54] ^ scrambler_state[15]));
    assign scrambled_data_high[12] = tx_data_reg[44] ^ (scrambler_state[13] ^ (scrambler_state[53] ^ scrambler_state[14]));
    assign scrambled_data_high[13] = tx_data_reg[45] ^ (scrambler_state[12] ^ (scrambler_state[52] ^ scrambler_state[13]));
    assign scrambled_data_high[14] = tx_data_reg[46] ^ (scrambler_state[11] ^ (scrambler_state[51] ^ scrambler_state[12]));
    assign scrambled_data_high[15] = tx_data_reg[47] ^ (scrambler_state[10] ^ (scrambler_state[50] ^ scrambler_state[11]));
    assign scrambled_data_high[16] = tx_data_reg[48] ^ (scrambler_state[9] ^ (scrambler_state[49] ^ scrambler_state[10]));
    assign scrambled_data_high[17] = tx_data_reg[49] ^ (scrambler_state[8] ^ (scrambler_state[48] ^ scrambler_state[9]));
    assign scrambled_data_high[18] = tx_data_reg[50] ^ (scrambler_state[7] ^ (scrambler_state[47] ^ scrambler_state[8]));
    assign scrambled_data_high[19] = tx_data_reg[51] ^ (scrambler_state[6] ^ (scrambler_state[46] ^ scrambler_state[7]));
    assign scrambled_data_high[20] = tx_data_reg[52] ^ (scrambler_state[5] ^ (scrambler_state[45] ^ scrambler_state[6]));
    assign scrambled_data_high[21] = tx_data_reg[53] ^ (scrambler_state[4] ^ (scrambler_state[44] ^ scrambler_state[5]));
    assign scrambled_data_high[22] = tx_data_reg[54] ^ (scrambler_state[3] ^ (scrambler_state[43] ^ scrambler_state[4]));
    assign scrambled_data_high[23] = tx_data_reg[55] ^ (scrambler_state[2] ^ (scrambler_state[42] ^ scrambler_state[3]));
    assign scrambled_data_high[24] = tx_data_reg[56] ^ (scrambler_state[1] ^ (scrambler_state[41] ^ scrambler_state[2]));
    assign scrambled_data_high[25] = tx_data_reg[57] ^ (scrambler_state[0] ^ (scrambler_state[40] ^ scrambler_state[1]));
    assign scrambled_data_high[26] = tx_data_reg[58] ^ (next_bit ^ (scrambler_state[39] ^ scrambler_state[0]));
    assign scrambled_data_high[27] = tx_data_reg[59] ^ (scrambler_state[57] ^ scrambler_state[38]);
    assign scrambled_data_high[28] = tx_data_reg[60] ^ (scrambler_state[56] ^ scrambler_state[37]);
    assign scrambled_data_high[29] = tx_data_reg[61] ^ (scrambler_state[55] ^ scrambler_state[36]);
    assign scrambled_data_high[30] = tx_data_reg[62] ^ (scrambler_state[54] ^ scrambler_state[35]);
    assign scrambled_data_high[31] = tx_data_reg[63] ^ (scrambler_state[53] ^ scrambler_state[34]);
    
    // 流水线寄存器 - 关键路径切割
    always @(posedge clk) begin
        if (rst) begin
            scrambled_data_stage1_low <= 32'h0;
            scrambled_data_stage1_high <= 32'h0;
            tx_valid_stage1 <= 1'b0;
        end else begin
            scrambled_data_stage1_low <= scrambled_data_low;
            scrambled_data_stage1_high <= scrambled_data_high;
            tx_valid_stage1 <= tx_valid_reg;
        end
    end
    
    // 组合最终的加扰数据
    assign scrambled_data = {scrambled_data_stage1_high, scrambled_data_stage1_low};
    
    // 最终数据编码
    always @(posedge clk) begin
        if (rst) begin
            encoded_data <= 66'h0;
            enc_valid <= 1'b0;
        end else begin
            if (tx_valid_stage1) begin
                encoded_data <= {scrambled_data, SYNC_HEADER};
                enc_valid <= 1'b1;
            end else begin
                enc_valid <= 1'b0;
            end
        end
    end
endmodule