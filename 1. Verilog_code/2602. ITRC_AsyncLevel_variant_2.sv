//SystemVerilog
module ITRC_AsyncLevel #(
    parameter PRIORITY = 4'hF
)(
    input clk,
    input rst_async,
    input [15:0] int_level,
    input en,
    output reg [3:0] int_id
);
    wire [15:0] masked_int;
    reg [15:0] masked_int_buf1, masked_int_buf2;
    reg [3:0] int_id_stage1, int_id_stage2;
    reg en_buf;
    reg [7:0] high_bits_or;
    reg reset_sync;
    
    // 使能信号同步
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) en_buf <= 1'b0;
        else en_buf <= en;
    end
    
    // 中断信号掩码
    assign masked_int = int_level & {16{en_buf}};
    
    // 中断信号缓冲
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            masked_int_buf1 <= 16'h0000;
            masked_int_buf2 <= 16'h0000;
        end else begin
            masked_int_buf1 <= masked_int;
            masked_int_buf2 <= masked_int;
        end
    end
    
    // 优化后的优先级编码器 - 第一级
    always @(*) begin
        casez (masked_int_buf1[15:8])
            8'b1???????: int_id_stage1 = 4'hF;
            8'b01??????: int_id_stage1 = 4'hE;
            8'b001?????: int_id_stage1 = 4'hD;
            8'b0001????: int_id_stage1 = 4'hC;
            8'b00001???: int_id_stage1 = 4'hB;
            8'b000001??: int_id_stage1 = 4'hA;
            8'b0000001?: int_id_stage1 = 4'h9;
            8'b00000001: int_id_stage1 = 4'h8;
            default:     int_id_stage1 = 4'h0;
        endcase
    end
    
    // 优化后的优先级编码器 - 第二级
    always @(*) begin
        casez (masked_int_buf2[7:0])
            8'b1???????: int_id_stage2 = 4'h7;
            8'b01??????: int_id_stage2 = 4'h6;
            8'b001?????: int_id_stage2 = 4'h5;
            8'b0001????: int_id_stage2 = 4'h4;
            8'b00001???: int_id_stage2 = 4'h3;
            8'b000001??: int_id_stage2 = 4'h2;
            8'b0000001?: int_id_stage2 = 4'h1;
            8'b00000001: int_id_stage2 = 4'h0;
            default:     int_id_stage2 = 4'h0;
        endcase
    end
    
    // 最终优先级选择
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            high_bits_or <= 8'h00;
            int_id <= 4'h0;
        end else begin
            high_bits_or <= |masked_int_buf1[15:8];
            int_id <= high_bits_or ? int_id_stage1 : int_id_stage2;
        end
    end
    
    // 复位同步
    always @(posedge clk, posedge rst_async) begin
        if (rst_async) reset_sync <= 1'b1;
        else reset_sync <= 1'b0;
    end
endmodule