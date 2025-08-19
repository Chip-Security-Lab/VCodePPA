//SystemVerilog
module crc5_sync_reset(
    input wire clk,
    input wire rst,
    input wire en,
    input wire [4:0] data,
    output wire [4:0] crc
);
    parameter [4:0] POLY = 5'h05; // CRC-5-USB: x^5 + x^2 + 1
    
    // 流水线阶段寄存器
    reg [4:0] crc_stage1, crc_stage2, crc_stage3;
    reg [4:0] data_stage1, data_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 阶段1: 初始CRC计算
    wire feedback = data[4] ^ crc_stage3[4];
    
    always @(posedge clk) begin
        if (rst) begin
            crc_stage1 <= 5'h1F;
            data_stage1 <= 5'h0;
            valid_stage1 <= 1'b0;
        end
        else if (en) begin
            crc_stage1[0] <= feedback;
            crc_stage1[1] <= crc_stage3[0];
            crc_stage1[2] <= crc_stage3[1] ^ feedback;
            crc_stage1[3] <= crc_stage3[2];
            crc_stage1[4] <= crc_stage3[3];
            data_stage1 <= data;
            valid_stage1 <= 1'b1;
        end
        else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 阶段2: 中间处理阶段
    always @(posedge clk) begin
        if (rst) begin
            crc_stage2 <= 5'h1F;
            data_stage2 <= 5'h0;
            valid_stage2 <= 1'b0;
        end
        else begin
            crc_stage2 <= crc_stage1;
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 阶段3: 最终CRC结果
    always @(posedge clk) begin
        if (rst) begin
            crc_stage3 <= 5'h1F;
            valid_stage3 <= 1'b0;
        end
        else begin
            crc_stage3 <= crc_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出CRC结果
    assign crc = crc_stage3;
    
endmodule