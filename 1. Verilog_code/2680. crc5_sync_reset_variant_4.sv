//SystemVerilog
module crc5_sync_reset(
    input wire clk,
    input wire rst,
    input wire en,
    input wire [4:0] data,
    output reg [4:0] crc
);
    parameter [4:0] POLY = 5'h05;
    
    reg [4:0] data_stage1, data_stage2;
    reg [4:0] crc_stage1, crc_stage2;
    reg valid_stage1, valid_stage2;
    reg feedback_bit_stage2;
    
    // 预计算反馈位和中间结果
    wire feedback_bit_stage1 = data[4] ^ crc[4];
    wire [4:0] next_crc_stage2 = {
        crc_stage2[3],
        crc_stage2[2],
        crc_stage2[1] ^ feedback_bit_stage2,
        crc_stage2[0],
        feedback_bit_stage2
    };
    
    always @(posedge clk) begin
        if (rst) begin
            data_stage1 <= 5'h0;
            crc_stage1 <= 5'h1F;
            valid_stage1 <= 1'b0;
            feedback_bit_stage2 <= 1'b0;
            data_stage2 <= 5'h0;
            crc_stage2 <= 5'h1F;
            valid_stage2 <= 1'b0;
            crc <= 5'h1F;
        end else begin
            // 第一级流水线
            if (en) begin
                data_stage1 <= data;
                crc_stage1 <= crc;
                valid_stage1 <= 1'b1;
                feedback_bit_stage2 <= feedback_bit_stage1;
            end else begin
                valid_stage1 <= 1'b0;
            end
            
            // 第二级流水线
            data_stage2 <= data_stage1;
            crc_stage2 <= crc_stage1;
            valid_stage2 <= valid_stage1;
            
            // 最终输出
            if (valid_stage2) begin
                crc <= next_crc_stage2;
            end
        end
    end
endmodule