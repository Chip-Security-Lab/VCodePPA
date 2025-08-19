//SystemVerilog
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
    reg [4:0] syndrome;
    
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
    
    // 编码流水线
    always @(posedge clk) begin
        // Stage 1: Data expansion
        enc_stage1[30:5] <= data_in[25:0];
        enc_stage1[4:0] <= 5'b0;
        
        // Stage 2: Parity calculation - 展开for循环
        enc_stage2 <= enc_stage1;
        enc_stage2[0] <= ^(enc_stage1 & parity_mask_31_26(0)); // i=0, 2^0-1=0
        enc_stage2[1] <= ^(enc_stage1 & parity_mask_31_26(1)); // i=1, 2^1-1=1
        enc_stage2[3] <= ^(enc_stage1 & parity_mask_31_26(2)); // i=2, 2^2-1=3
        enc_stage2[7] <= ^(enc_stage1 & parity_mask_31_26(3)); // i=3, 2^3-1=7
        enc_stage2[15] <= ^(enc_stage1 & parity_mask_31_26(4)); // i=4, 2^4-1=15
        
        // Stage 3: Final output
        encoded_out <= enc_stage2;
    end
    
    // 解码流水线实现
    always @(posedge clk) begin
        // Stage 1: 计算校验位 - 展开for循环
        dec_stage1 <= received_in;
        syndrome[0] <= ^(received_in & parity_mask_31_26(0)) ^ received_in[0]; // i=0, 2^0-1=0
        syndrome[1] <= ^(received_in & parity_mask_31_26(1)) ^ received_in[1]; // i=1, 2^1-1=1
        syndrome[2] <= ^(received_in & parity_mask_31_26(2)) ^ received_in[3]; // i=2, 2^2-1=3
        syndrome[3] <= ^(received_in & parity_mask_31_26(3)) ^ received_in[7]; // i=3, 2^3-1=7
        syndrome[4] <= ^(received_in & parity_mask_31_26(4)) ^ received_in[15]; // i=4, 2^4-1=15
        
        // Stage 2: 纠正错误
        dec_stage2 <= dec_stage1;
        
        // 使用组合逻辑直接处理所有可能的综合症情况
        if(|syndrome) begin
            case(syndrome)
                5'd1:  dec_stage2[0]  <= ~dec_stage1[0];
                5'd2:  dec_stage2[1]  <= ~dec_stage1[1];
                5'd3:  dec_stage2[2]  <= ~dec_stage1[2];
                5'd4:  dec_stage2[3]  <= ~dec_stage1[3];
                5'd5:  dec_stage2[4]  <= ~dec_stage1[4];
                5'd6:  dec_stage2[5]  <= ~dec_stage1[5];
                5'd7:  dec_stage2[6]  <= ~dec_stage1[6];
                5'd8:  dec_stage2[7]  <= ~dec_stage1[7];
                5'd9:  dec_stage2[8]  <= ~dec_stage1[8];
                5'd10: dec_stage2[9]  <= ~dec_stage1[9];
                5'd11: dec_stage2[10] <= ~dec_stage1[10];
                5'd12: dec_stage2[11] <= ~dec_stage1[11];
                5'd13: dec_stage2[12] <= ~dec_stage1[12];
                5'd14: dec_stage2[13] <= ~dec_stage1[13];
                5'd15: dec_stage2[14] <= ~dec_stage1[14];
                5'd16: dec_stage2[15] <= ~dec_stage1[15];
                5'd17: dec_stage2[16] <= ~dec_stage1[16];
                5'd18: dec_stage2[17] <= ~dec_stage1[17];
                5'd19: dec_stage2[18] <= ~dec_stage1[18];
                5'd20: dec_stage2[19] <= ~dec_stage1[19];
                5'd21: dec_stage2[20] <= ~dec_stage1[20];
                5'd22: dec_stage2[21] <= ~dec_stage1[21];
                5'd23: dec_stage2[22] <= ~dec_stage1[22];
                5'd24: dec_stage2[23] <= ~dec_stage1[23];
                5'd25: dec_stage2[24] <= ~dec_stage1[24];
                5'd26: dec_stage2[25] <= ~dec_stage1[25];
                5'd27: dec_stage2[26] <= ~dec_stage1[26];
                5'd28: dec_stage2[27] <= ~dec_stage1[27];
                5'd29: dec_stage2[28] <= ~dec_stage1[28];
                5'd30: dec_stage2[29] <= ~dec_stage1[29];
                5'd31: dec_stage2[30] <= ~dec_stage1[30];
                default: dec_stage2 <= dec_stage1; // 无效综合症，不纠正
            endcase
        end
        
        // Stage 3: 提取数据
        decoded_out <= {dec_stage2[30:16], dec_stage2[14:8], dec_stage2[6:5]};
    end
endmodule