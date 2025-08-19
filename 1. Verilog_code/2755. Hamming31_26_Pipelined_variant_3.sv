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
    reg [4:0] syndrome, syndrome_reg;
    reg [4:0] error_position;
    reg error_detected;
    
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
    
    // 编码流水线 - 阶段1：数据扩展
    always @(posedge clk) begin
        enc_stage1[30:5] <= data_in[25:0];
        enc_stage1[4:0] <= 5'b0;
    end
    
    // 编码流水线 - 阶段2：奇偶校验计算
    always @(posedge clk) begin
        enc_stage2 <= enc_stage1;
        enc_stage2[0] <= ^(enc_stage1 & parity_mask_31_26(0));
        enc_stage2[1] <= ^(enc_stage1 & parity_mask_31_26(1));
        enc_stage2[3] <= ^(enc_stage1 & parity_mask_31_26(2));
        enc_stage2[7] <= ^(enc_stage1 & parity_mask_31_26(3));
        enc_stage2[15] <= ^(enc_stage1 & parity_mask_31_26(4));
    end
    
    // 编码流水线 - 阶段3：最终输出
    always @(posedge clk) begin
        encoded_out <= enc_stage2;
    end
    
    // 解码流水线 - 阶段1：保存接收数据
    always @(posedge clk) begin
        dec_stage1 <= received_in;
    end
    
    // 解码流水线 - 阶段1：计算校验位
    always @(posedge clk) begin
        syndrome[0] <= ^(received_in & parity_mask_31_26(0)) ^ received_in[0];
        syndrome[1] <= ^(received_in & parity_mask_31_26(1)) ^ received_in[1];
        syndrome[2] <= ^(received_in & parity_mask_31_26(2)) ^ received_in[3];
        syndrome[3] <= ^(received_in & parity_mask_31_26(3)) ^ received_in[7];
        syndrome[4] <= ^(received_in & parity_mask_31_26(4)) ^ received_in[15];
    end
    
    // 解码流水线 - 阶段2：错误识别
    always @(posedge clk) begin
        syndrome_reg <= syndrome;
        error_detected <= |syndrome;
        if(|syndrome && syndrome < 31) begin
            error_position <= syndrome;
        end else begin
            error_position <= 5'b0;
        end
    end
    
    // 解码流水线 - 阶段2：错误纠正
    always @(posedge clk) begin
        dec_stage2 <= dec_stage1;
        if(error_detected && error_position < 31) begin
            dec_stage2[error_position] <= ~dec_stage1[error_position];
        end
    end
    
    // 解码流水线 - 阶段3：提取数据
    always @(posedge clk) begin
        decoded_out <= {dec_stage2[30:16], dec_stage2[14:8], dec_stage2[6:5]};
    end
endmodule