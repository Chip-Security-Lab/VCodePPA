//SystemVerilog
module crc_error_injection (
    input clk, 
    input rst_n,
    input inject_err,
    input [7:0] data_in,
    input data_valid,
    output reg [15:0] crc,
    output reg data_valid_out
);
    // 第一级流水：输入数据处理
    reg [7:0] data_stage1;
    reg inject_err_stage1;
    reg [15:0] crc_stage1;
    reg valid_stage1;
    
    // 第二级流水：CRC计算 - 前4位
    reg [15:0] crc_stage2;
    reg [3:0] data_remain_stage2;
    reg valid_stage2;
    
    // 第三级流水：CRC计算 - 后4位
    reg [15:0] crc_stage3;
    reg valid_stage3;
    
    // 优化的CRC计算常量表 - 预计算CRC位模式
    wire [15:0] crc_lut [0:15];
    assign crc_lut[0]  = 16'h0000;
    assign crc_lut[1]  = 16'h8005;
    assign crc_lut[2]  = 16'h800F;
    assign crc_lut[3]  = 16'h000A;
    assign crc_lut[4]  = 16'h801B;
    assign crc_lut[5]  = 16'h001E;
    assign crc_lut[6]  = 16'h0014;
    assign crc_lut[7]  = 16'h8011;
    assign crc_lut[8]  = 16'h8033;
    assign crc_lut[9]  = 16'h0036;
    assign crc_lut[10] = 16'h003C;
    assign crc_lut[11] = 16'h8039;
    assign crc_lut[12] = 16'h0028;
    assign crc_lut[13] = 16'h802D;
    assign crc_lut[14] = 16'h8027;
    assign crc_lut[15] = 16'h0022;
    
    // 流水线第一级 - 输入数据处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 8'h0;
            inject_err_stage1 <= 1'b0;
            crc_stage1 <= 16'h0;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= data_valid;
            if (data_valid) begin
                data_stage1 <= data_in ^ {8{inject_err}}; // 优化XOR操作
                inject_err_stage1 <= inject_err;
                crc_stage1 <= crc;
            end
        end
    end
    
    // CRC16计算流水线 - 前4位 (bit 0-3)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_stage2 <= 16'h0;
            data_remain_stage2 <= 4'h0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                // 使用查找表优化的4位CRC计算
                crc_stage2 <= crc_calculate_4bit_lut(data_stage1[3:0], crc_stage1);
                data_remain_stage2 <= data_stage1[7:4];
            end
        end
    end
    
    // CRC16计算流水线 - 后4位 (bit 4-7)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_stage3 <= 16'h0;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            if (valid_stage2) begin
                // 使用查找表优化的4位CRC计算
                crc_stage3 <= crc_calculate_4bit_lut(data_remain_stage2, crc_stage2);
            end
        end
    end
    
    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc <= 16'h0;
            data_valid_out <= 1'b0;
        end else begin
            data_valid_out <= valid_stage3;
            if (valid_stage3) begin
                crc <= crc_stage3;
            end
        end
    end
    
    // 并行化的4位CRC计算 - 使用查找表优化
    function [15:0] crc_calculate_4bit_lut;
        input [3:0] data;
        input [15:0] crc_in;
        reg [3:0] index;
        begin
            // 并行计算4位输入的CRC，减少循环
            index = data ^ crc_in[15:12];
            crc_calculate_4bit_lut = {crc_in[11:0], 4'b0000} ^ crc_lut[index];
        end
    endfunction
    
    // 原始bit-by-bit计算方法 - 保留用于功能验证
    function [15:0] crc_calculate_4bit;
        input [3:0] data;
        input [15:0] crc_in;
        reg [15:0] crc_out;
        reg [15:0] crc_temp;
        reg feedback;
        integer i;
        begin
            crc_out = crc_in;
            
            // 优化循环内计算，减少关键路径深度
            for (i = 0; i < 4; i = i + 1) begin
                feedback = data[i] ^ crc_out[15];
                crc_temp = {crc_out[14:0], 1'b0};
                crc_out = feedback ? (crc_temp ^ 16'h8005) : crc_temp;
            end
            
            crc_calculate_4bit = crc_out;
        end
    endfunction
endmodule