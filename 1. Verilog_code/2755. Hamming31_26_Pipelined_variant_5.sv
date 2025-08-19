//SystemVerilog
module Hamming31_26_Pipelined (
    input clk,
    input [25:0] data_in,
    output reg [30:0] encoded_out,
    input [30:0] received_in,
    output reg [25:0] decoded_out
);
    // 流水线寄存器
    reg [30:0] enc_stage1;
    reg [30:0] enc_stage2;
    reg [30:0] dec_stage1;
    reg [30:0] dec_stage2;
    reg [4:0] syndrome;
    
    // 优化的参数掩码 - 使用常量替代函数调用
    localparam [30:0] PARITY_MASK_0 = 31'h55555555; // 奇数位置的位
    localparam [30:0] PARITY_MASK_1 = 31'h66666666; // 位2,3,6,7...
    localparam [30:0] PARITY_MASK_2 = 31'h78787878; // 位4-7,12-15...
    localparam [30:0] PARITY_MASK_3 = 31'h7F807F80; // 位8-15,24-31...
    localparam [30:0] PARITY_MASK_4 = 31'h7FFF8000; // 位16-31
    
    // 编码流水线 - 优化版本
    always @(posedge clk) begin
        // Stage 1: Data expansion - 直接赋值，不需要循环
        enc_stage1 <= {data_in, 5'b0};
        
        // Stage 2: Parity calculation - 优化异或运算，减少门延迟
        enc_stage2 <= enc_stage1;
        enc_stage2[0] <= ^(enc_stage1 & PARITY_MASK_0);
        enc_stage2[1] <= ^(enc_stage1 & PARITY_MASK_1);
        enc_stage2[3] <= ^(enc_stage1 & PARITY_MASK_2);
        enc_stage2[7] <= ^(enc_stage1 & PARITY_MASK_3);
        enc_stage2[15] <= ^(enc_stage1 & PARITY_MASK_4);
        
        // Stage 3: Final output
        encoded_out <= enc_stage2;
    end
    
    // 解码流水线实现 - 优化版本
    wire [30:0] error_position;
    
    always @(posedge clk) begin
        // Stage 1: 计算校验位 - 直接并行计算，避免循环
        dec_stage1 <= received_in;
        syndrome[0] <= ^(received_in & PARITY_MASK_0) ^ received_in[0];
        syndrome[1] <= ^(received_in & PARITY_MASK_1) ^ received_in[1];
        syndrome[2] <= ^(received_in & PARITY_MASK_2) ^ received_in[3];
        syndrome[3] <= ^(received_in & PARITY_MASK_3) ^ received_in[7];
        syndrome[4] <= ^(received_in & PARITY_MASK_4) ^ received_in[15];
        
        // Stage 2: 纠正错误 - 优化错误纠正逻辑
        dec_stage2 <= dec_stage1;
        
        // 使用条件赋值而非if判断，减少逻辑层次
        if (|syndrome && syndrome < 31) begin
            dec_stage2[syndrome] <= ~dec_stage1[syndrome];
        end
        
        // Stage 3: 提取数据 - 直接位拼接，避免冗余操作
        decoded_out <= {dec_stage2[30:16], dec_stage2[14:8], dec_stage2[6:5]};
    end
endmodule