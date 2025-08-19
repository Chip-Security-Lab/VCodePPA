//SystemVerilog
module crc64_pipelined (
    input clk, en,
    input [63:0] data,
    output reg [63:0] crc
);
    parameter POLY = 64'h42F0E1EBA9EA3693;
    
    // 优化后的流水线阶段
    reg [63:0] stage[0:3];
    wire [3:0] msb_sel;
    wire [63:0] poly_mask[0:2];
    
    // 提前计算多项式掩码，减少关键路径
    assign msb_sel = {stage[2][63], stage[1][63], stage[0][63], crc[63]};
    assign poly_mask[0] = {64{msb_sel[0]}} & POLY;
    assign poly_mask[1] = {64{msb_sel[1]}} & POLY;
    assign poly_mask[2] = {64{msb_sel[2]}} & POLY;
    
    always @(posedge clk) begin
        if (en) begin
            // 简化第一级管道，减少数据移位逻辑
            stage[0] <= {data[56:0], 7'b0} ^ crc;
            // 通过预计算掩码减少时钟到输出延迟
            stage[1] <= stage[0] ^ poly_mask[0];
            stage[2] <= stage[1] ^ poly_mask[1];
            stage[3] <= stage[2] ^ poly_mask[2];
            crc <= stage[3];
        end
    end
endmodule