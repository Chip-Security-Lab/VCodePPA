//SystemVerilog
module Hamming31_26_Pipelined (
    input clk,
    input [25:0] data_in,
    output reg [30:0] encoded_out,
    input [30:0] received_in,
    output reg [25:0] decoded_out
);
    // 增加流水线级数的寄存器
    reg [30:0] enc_stage1, enc_stage2, enc_stage3, enc_stage4;
    reg [30:0] dec_stage1, dec_stage2, dec_stage3, dec_stage4;
    
    // 为编码流水线增加中间变量
    reg [30:0] enc_parity_temp1, enc_parity_temp2;
    
    // 解码流水线中间变量
    reg [4:0] syndrome_stage1, syndrome_stage2, syndrome_stage3;
    reg [4:0] error_pos;
    
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
    
    // 编码流水线 - 增加级数拆分复杂操作
    always @(posedge clk) begin
        // Stage 1: Data expansion
        enc_stage1[30:5] <= data_in[25:0];
        enc_stage1[4:0] <= 5'b0;
        
        // Stage 2: 计算前2个校验位
        enc_stage2 <= enc_stage1;
        enc_parity_temp1[0] <= ^(enc_stage1 & parity_mask_31_26(0));
        enc_parity_temp1[1] <= ^(enc_stage1 & parity_mask_31_26(1));
        
        // Stage 3: 计算后3个校验位
        enc_stage3 <= enc_stage2;
        enc_parity_temp2[0] <= enc_parity_temp1[0];
        enc_parity_temp2[1] <= enc_parity_temp1[1];
        enc_parity_temp2[2] <= ^(enc_stage2 & parity_mask_31_26(2));
        enc_parity_temp2[3] <= ^(enc_stage2 & parity_mask_31_26(3));
        enc_parity_temp2[4] <= ^(enc_stage2 & parity_mask_31_26(4));
        
        // Stage 4: 组合校验位
        enc_stage4 <= enc_stage3;
        enc_stage4[0] <= enc_parity_temp2[0];
        enc_stage4[1] <= enc_parity_temp2[1];
        enc_stage4[3] <= enc_parity_temp2[2];
        enc_stage4[7] <= enc_parity_temp2[3];
        enc_stage4[15] <= enc_parity_temp2[4];
        
        // Stage 5: Final output
        encoded_out <= enc_stage4;
    end
    
    // 解码流水线 - 增加级数拆分复杂操作
    always @(posedge clk) begin
        // Stage 1: 保存接收数据
        dec_stage1 <= received_in;
        
        // Stage 2: 计算前3个校验位
        dec_stage2 <= dec_stage1;
        syndrome_stage1[0] <= ^(dec_stage1 & parity_mask_31_26(0)) ^ dec_stage1[0];
        syndrome_stage1[1] <= ^(dec_stage1 & parity_mask_31_26(1)) ^ dec_stage1[1];
        syndrome_stage1[2] <= ^(dec_stage1 & parity_mask_31_26(2)) ^ dec_stage1[3];
        
        // Stage 3: 计算后2个校验位
        dec_stage3 <= dec_stage2;
        syndrome_stage2 <= syndrome_stage1;
        syndrome_stage2[3] <= ^(dec_stage2 & parity_mask_31_26(3)) ^ dec_stage2[7];
        syndrome_stage2[4] <= ^(dec_stage2 & parity_mask_31_26(4)) ^ dec_stage2[15];
        
        // Stage 4: 计算错误位置
        dec_stage4 <= dec_stage3;
        syndrome_stage3 <= syndrome_stage2;
        if(|syndrome_stage2) begin
            error_pos <= syndrome_stage2;
        end
        else begin
            error_pos <= 5'b0;
        end
        
        // Stage 5: 纠错处理
        if(|syndrome_stage3 && error_pos < 31) begin
            decoded_out[24:10] <= dec_stage4[30:16]; // 高位数据
            decoded_out[9:3] <= dec_stage4[14:8];    // 中间数据
            
            if(error_pos == 5) begin
                decoded_out[0] <= ~dec_stage4[5];
            end
            else if(error_pos == 6) begin
                decoded_out[1] <= ~dec_stage4[6];
            end
            else if(error_pos >= 8 && error_pos <= 14) begin
                decoded_out[error_pos-5] <= ~dec_stage4[error_pos];
            end
            else if(error_pos >= 16 && error_pos <= 30) begin
                decoded_out[error_pos-6] <= ~dec_stage4[error_pos];
            end
            else begin
                decoded_out[2:0] <= dec_stage4[6:5]; // 低位数据, 可能不需要纠错
            end
        end
        else begin
            decoded_out <= {dec_stage4[30:16], dec_stage4[14:8], dec_stage4[6:5]};
        end
    end
endmodule