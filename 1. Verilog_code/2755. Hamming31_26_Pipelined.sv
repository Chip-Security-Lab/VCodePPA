module Hamming31_26_Pipelined (
    input clk,
    input [25:0] data_in,
    output reg [30:0] encoded_out,
    input [30:0] received_in,
    output reg [25:0] decoded_out
);
    // 流水线寄存器
    reg [30:0] enc_stage1, enc_stage2;
    reg [30:0] dec_stage1, dec_stage2;
    
    // 参数掩码生成函数实现
    function [30:0] parity_mask_31_26;
        input [2:0] pos;
        begin
            case(pos)
                3'd0: parity_mask_31_26 = 31'h55555555; // 奇数位置的位
                3'd1: parity_mask_31_26 = 31'h66666666; // 位2,3,6,7...
                3'd2: parity_mask_31_26 = 31'h78787878; // 位4-7,12-15...
                3'd3: parity_mask_31_26 = 31'h7F807F80; // 位8-15,24-31...
                3'd4: parity_mask_31_26 = 31'h7FFF8000; // 位16-31
                default: parity_mask_31_26 = 31'h0;
            endcase
        end
    endfunction
    
    integer i;
    
    // 编码流水线
    always @(posedge clk) begin
        // Stage 1: Data expansion
        enc_stage1[30:5] <= data_in[25:0];
        enc_stage1[4:0] <= 5'b0;
        
        // Stage 2: Parity calculation
        enc_stage2 <= enc_stage1;
        for(i=0; i<5; i=i+1) begin
            enc_stage2[2**i -1] <= ^(enc_stage1 & parity_mask_31_26(i));
        end
        
        // Stage 3: Final output
        encoded_out <= enc_stage2;
    end
    
    // 解码流水线实现
    reg [4:0] syndrome;
    always @(posedge clk) begin
        // Stage 1: 计算校验位
        dec_stage1 <= received_in;
        for(i=0; i<5; i=i+1) begin
            syndrome[i] <= ^(received_in & parity_mask_31_26(i)) ^ received_in[2**i -1];
        end
        
        // Stage 2: 纠正错误
        dec_stage2 <= dec_stage1;
        // 简化版错误纠正逻辑
        if(|syndrome) begin
            // 错误位置计算 (简化实现)
            if(syndrome < 31)
                dec_stage2[syndrome] <= ~dec_stage1[syndrome];
        end
        
        // Stage 3: 提取数据
        decoded_out <= {dec_stage2[30:16], dec_stage2[14:8], dec_stage2[6:5]};
    end
endmodule