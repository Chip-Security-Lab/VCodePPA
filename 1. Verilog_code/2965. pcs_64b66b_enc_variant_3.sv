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
    reg [57:0] scrambler_state;
    
    // 使用两个缓冲区减少高扇出负载
    reg [63:0] tx_data_buf;
    reg [57:0] scrambler_state_buf;
    
    // 简化的线性反馈移位寄存器位操作
    wire next_bit = scrambler_state[57] ^ scrambler_state[38];
    
    // 预计算scrambler序列，减少关键路径逻辑深度
    wire [57:0] scrambler_seq;
    assign scrambler_seq[0] = scrambler_state[57] ^ scrambler_state[38];
    assign scrambler_seq[1] = scrambler_state[56] ^ scrambler_state[37];
    assign scrambler_seq[2] = scrambler_state[55] ^ scrambler_state[36];
    assign scrambler_seq[3] = scrambler_state[54] ^ scrambler_state[35];
    assign scrambler_seq[4] = scrambler_state[53] ^ scrambler_state[34];
    assign scrambler_seq[5] = scrambler_state[52] ^ scrambler_state[33];
    assign scrambler_seq[6] = scrambler_state[51] ^ scrambler_state[32];
    assign scrambler_seq[7] = scrambler_state[50] ^ scrambler_state[31];
    assign scrambler_seq[8] = scrambler_state[49] ^ scrambler_state[30];
    assign scrambler_seq[9] = scrambler_state[48] ^ scrambler_state[29];
    assign scrambler_seq[10] = scrambler_state[47] ^ scrambler_state[28];
    assign scrambler_seq[11] = scrambler_state[46] ^ scrambler_state[27];
    assign scrambler_seq[12] = scrambler_state[45] ^ scrambler_state[26];
    assign scrambler_seq[13] = scrambler_state[44] ^ scrambler_state[25];
    assign scrambler_seq[14] = scrambler_state[43] ^ scrambler_state[24];
    assign scrambler_seq[15] = scrambler_state[42] ^ scrambler_state[23];
    assign scrambler_seq[16] = scrambler_state[41] ^ scrambler_state[22];
    assign scrambler_seq[17] = scrambler_state[40] ^ scrambler_state[21];
    assign scrambler_seq[18] = scrambler_state[39] ^ scrambler_state[20];
    assign scrambler_seq[19] = scrambler_state[38] ^ scrambler_state[19];
    assign scrambler_seq[20] = scrambler_state[37] ^ scrambler_state[18];
    assign scrambler_seq[21] = scrambler_state[36] ^ scrambler_state[17];
    assign scrambler_seq[22] = scrambler_state[35] ^ scrambler_state[16];
    assign scrambler_seq[23] = scrambler_state[34] ^ scrambler_state[15];
    assign scrambler_seq[24] = scrambler_state[33] ^ scrambler_state[14];
    assign scrambler_seq[25] = scrambler_state[32] ^ scrambler_state[13];
    assign scrambler_seq[26] = scrambler_state[31] ^ scrambler_state[12];
    assign scrambler_seq[27] = scrambler_state[30] ^ scrambler_state[11];
    assign scrambler_seq[28] = scrambler_state[29] ^ scrambler_state[10];
    assign scrambler_seq[29] = scrambler_state[28] ^ scrambler_state[9];
    assign scrambler_seq[30] = scrambler_state[27] ^ scrambler_state[8];
    assign scrambler_seq[31] = scrambler_state[26] ^ scrambler_state[7];
    assign scrambler_seq[32] = scrambler_state[25] ^ scrambler_state[6];
    assign scrambler_seq[33] = scrambler_state[24] ^ scrambler_state[5];
    assign scrambler_seq[34] = scrambler_state[23] ^ scrambler_state[4];
    assign scrambler_seq[35] = scrambler_state[22] ^ scrambler_state[3];
    assign scrambler_seq[36] = scrambler_state[21] ^ scrambler_state[2];
    assign scrambler_seq[37] = scrambler_state[20] ^ scrambler_state[1];
    assign scrambler_seq[38] = scrambler_state[19] ^ scrambler_state[0];
    assign scrambler_seq[39] = scrambler_state[18] ^ scrambler_seq[0];
    assign scrambler_seq[40] = scrambler_state[17] ^ scrambler_seq[1];
    assign scrambler_seq[41] = scrambler_state[16] ^ scrambler_seq[2];
    assign scrambler_seq[42] = scrambler_state[15] ^ scrambler_seq[3];
    assign scrambler_seq[43] = scrambler_state[14] ^ scrambler_seq[4];
    assign scrambler_seq[44] = scrambler_state[13] ^ scrambler_seq[5];
    assign scrambler_seq[45] = scrambler_state[12] ^ scrambler_seq[6];
    assign scrambler_seq[46] = scrambler_state[11] ^ scrambler_seq[7];
    assign scrambler_seq[47] = scrambler_state[10] ^ scrambler_seq[8];
    assign scrambler_seq[48] = scrambler_state[9] ^ scrambler_seq[9];
    assign scrambler_seq[49] = scrambler_state[8] ^ scrambler_seq[10];
    assign scrambler_seq[50] = scrambler_state[7] ^ scrambler_seq[11];
    assign scrambler_seq[51] = scrambler_state[6] ^ scrambler_seq[12];
    assign scrambler_seq[52] = scrambler_state[5] ^ scrambler_seq[13];
    assign scrambler_seq[53] = scrambler_state[4] ^ scrambler_seq[14];
    assign scrambler_seq[54] = scrambler_state[3] ^ scrambler_seq[15];
    assign scrambler_seq[55] = scrambler_state[2] ^ scrambler_seq[16];
    assign scrambler_seq[56] = scrambler_state[1] ^ scrambler_seq[17];
    assign scrambler_seq[57] = scrambler_state[0] ^ scrambler_seq[18];
    
    // 单一缓冲寄存器减少扇出并提高时序性能
    always @(posedge clk) begin
        if (rst) begin
            tx_data_buf <= 64'h0;
            scrambler_state_buf <= 58'h0;
        end else if (tx_valid) begin
            tx_data_buf <= tx_data;
            scrambler_state_buf <= scrambler_state;
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            scrambler_state <= 58'h1FF;
            enc_valid <= 0;
            encoded_data <= 66'h0;
        end else if (tx_valid) begin
            // 更新scrambler状态，将位反馈移入
            scrambler_state <= {scrambler_state[56:0], next_bit};
            
            // 并行XOR操作，使用优化的数据路径
            encoded_data[65:2] <= tx_data_buf ^ {scrambler_state_buf[57:0], scrambler_seq[57]};
            
            // 添加同步头
            encoded_data[1:0] <= SYNC_HEADER;
            enc_valid <= 1;
        end else begin
            enc_valid <= 0;
        end
    end
endmodule