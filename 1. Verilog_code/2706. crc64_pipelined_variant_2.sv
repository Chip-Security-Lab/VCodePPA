//SystemVerilog
module crc64_pipelined (
    input clk, en,
    input [63:0] data,
    output reg [63:0] crc
);
    parameter POLY = 64'h42F0E1EBA9EA3693;
    
    // 流水线寄存器
    reg [63:0] xor_result;       // 存储初始异或结果
    reg [63:0] poly_to_xor;      // 存储将要异或的多项式值
    reg xor_needed;              // 存储是否需要异或操作
    
    // 阶段寄存器
    reg [63:0] stage[0:3];
    
    // 额外的中间寄存器，用于切分组合逻辑
    reg [63:0] stage1_inter;     // 第1阶段中间结果
    reg [63:0] stage2_inter;     // 第2阶段中间结果
    reg [63:0] stage3_inter;     // 第3阶段中间结果
    
    always @(posedge clk) begin
        if (en) begin
            // 第0阶段 - 将输入数据与CRC的一部分异或
            xor_result <= data ^ {crc[56:0], 7'b0};
            
            // 存储是否需要异或操作的决策
            if (xor_result[63]) begin
                xor_needed <= 1'b1;
                poly_to_xor <= POLY;
            end else begin
                xor_needed <= 1'b0;
                poly_to_xor <= 64'h0;
            end
            
            // 第1阶段 - 将预计算的POLY值与前一阶段结果异或
            stage[0] <= xor_result;
            stage1_inter <= stage[0] ^ poly_to_xor;
            
            if (stage1_inter[63]) begin
                xor_needed <= 1'b1;
                poly_to_xor <= POLY;
            end else begin
                xor_needed <= 1'b0;
                poly_to_xor <= 64'h0;
            end
            
            // 第2阶段
            stage[1] <= stage1_inter;
            stage2_inter <= stage[1] ^ poly_to_xor;
            
            if (stage2_inter[63]) begin
                xor_needed <= 1'b1;
                poly_to_xor <= POLY;
            end else begin
                xor_needed <= 1'b0;
                poly_to_xor <= 64'h0;
            end
            
            // 第3阶段
            stage[2] <= stage2_inter;
            stage3_inter <= stage[2] ^ poly_to_xor;
            
            // 最终阶段
            stage[3] <= stage3_inter;
            crc <= stage[3];
        end
    end
endmodule