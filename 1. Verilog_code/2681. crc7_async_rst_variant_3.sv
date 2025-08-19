//SystemVerilog
module crc7_async_rst(
    input wire clk,
    input wire arst_n,
    input wire [6:0] data,
    output reg [6:0] crc_out
);
    // CRC-7 polynomial: x^7 + x^3 + 1
    localparam [6:0] POLY = 7'h09;
    
    // 中间寄存器，用于切分数据路径
    reg data_bit_reg;
    reg crc_msb_reg;
    reg feedback_needed;
    reg [6:0] crc_shifted;
    reg [6:0] feedback_mask;
    
    // 流水线第一级：准备反馈信号
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            data_bit_reg <= 1'b0;
            crc_msb_reg <= 1'b0;
            feedback_needed <= 1'b0;
        end else begin
            data_bit_reg <= data[0];
            crc_msb_reg <= crc_out[6];
            feedback_needed <= crc_out[6] ^ data[0];
        end
    end
    
    // 流水线第二级：准备移位和掩码
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            crc_shifted <= 7'h0;
            feedback_mask <= 7'h0;
        end else begin
            crc_shifted <= {crc_out[5:0], 1'b0};
            feedback_mask <= feedback_needed ? POLY : 7'h0;
        end
    end
    
    // 流水线第三级：最终CRC计算
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            crc_out <= 7'h00;
        end else begin
            crc_out <= crc_shifted ^ feedback_mask;
        end
    end
    
endmodule