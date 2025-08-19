//SystemVerilog
module pipelined_crc16(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg [15:0] crc_out
);
    parameter [15:0] POLY = 16'h1021;
    
    reg [15:0] stage1, stage2, stage3;
    wire [3:0] xor_bits;
    wire [15:0] stage1_next, stage2_next, stage3_next, crc_next;
    wire [15:0] stage1_poly, stage2_poly, stage3_poly, crc_poly;
    
    // 预计算XOR条件位
    assign xor_bits = {
        stage3[15] ^ data_in[4],
        stage2[15] ^ data_in[5],
        stage1[15] ^ data_in[6],
        stage1[15] ^ data_in[7]
    };
    
    // 显式多路复用器实现
    assign stage1_poly = xor_bits[0] ? POLY : 16'h0;
    assign stage2_poly = xor_bits[1] ? POLY : 16'h0;
    assign stage3_poly = xor_bits[2] ? POLY : 16'h0;
    assign crc_poly = xor_bits[3] ? POLY : 16'h0;
    
    // 并行计算下一级状态
    assign stage1_next = {stage1[14:0], 1'b0} ^ stage1_poly;
    assign stage2_next = {stage1_next[14:0], 1'b0} ^ stage2_poly;
    assign stage3_next = {stage2_next[14:0], 1'b0} ^ stage3_poly;
    assign crc_next = {stage3_next[14:0], 1'b0} ^ crc_poly;
    
    always @(posedge clk) begin
        if (rst) begin
            stage1 <= 16'hFFFF;
            stage2 <= 16'hFFFF;
            stage3 <= 16'hFFFF;
            crc_out <= 16'hFFFF;
        end else if (data_valid) begin
            stage1 <= stage1_next;
            stage2 <= stage2_next;
            stage3 <= stage3_next;
            crc_out <= crc_next;
        end
    end
endmodule