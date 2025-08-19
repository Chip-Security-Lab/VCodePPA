//SystemVerilog
module crc_dual_clock (
    input clk_a, clk_b, rst,
    input [7:0] data_a,
    output reg [15:0] crc_b
);

    // 跨时钟域同步寄存器
    reg [7:0] data_sync_meta;
    reg [7:0] data_sync;
    
    // CRC计算寄存器
    reg [15:0] crc_reg;
    
    // 组合逻辑部分
    wire crc_feedback;
    wire [15:0] next_crc;
    
    // 反馈计算
    assign crc_feedback = crc_reg[15];
    
    // CRC下一状态计算
    assign next_crc[0] = data_sync[0] ^ crc_feedback;
    assign next_crc[1] = data_sync[1] ^ crc_reg[0];
    assign next_crc[2] = data_sync[2] ^ crc_reg[1] ^ crc_feedback;
    assign next_crc[3] = data_sync[3] ^ crc_reg[2];
    assign next_crc[4] = data_sync[4] ^ crc_reg[3];
    assign next_crc[5] = data_sync[5] ^ crc_reg[4] ^ crc_feedback;
    assign next_crc[6] = data_sync[6] ^ crc_reg[5];
    assign next_crc[7] = data_sync[7] ^ crc_reg[6];
    assign next_crc[8] = crc_reg[7];
    assign next_crc[9] = crc_reg[8];
    assign next_crc[10] = crc_reg[9];
    assign next_crc[11] = crc_reg[10];
    assign next_crc[12] = crc_reg[11];
    assign next_crc[13] = crc_reg[12];
    assign next_crc[14] = crc_reg[13];
    assign next_crc[15] = crc_reg[14] ^ crc_feedback;
    
    // 时序逻辑部分 - 时钟域A
    always @(posedge clk_a) begin
        data_sync_meta <= data_a;
        data_sync <= data_sync_meta;
    end
    
    // 时序逻辑部分 - 时钟域B
    always @(posedge clk_b) begin
        if (rst) begin
            crc_reg <= 16'hFFFF;
            crc_b <= 16'hFFFF;
        end else begin
            crc_reg <= next_crc;
            crc_b <= crc_reg;
        end
    end
    
endmodule