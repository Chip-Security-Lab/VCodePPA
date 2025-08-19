//SystemVerilog
module pipelined_crc16(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg [15:0] crc_out,
    output reg crc_valid
);
    // 参数定义 - 使用本地常量避免高扇出
    localparam [15:0] POLY_VAL = 16'h1021;
    
    // 定义流水线寄存器和控制信号
    reg [15:0] crc_reg;
    reg [15:0] stage1_result, stage2_result, stage3_result, stage4_result;
    reg [3:0] data_bits_s1, data_bits_s2;
    reg [2:0] data_bits_s3, data_bits_s3_buf1, data_bits_s3_buf2;
    reg valid_s1, valid_s2, valid_s3, valid_s4;
    
    // POLY 缓冲寄存器 - 分散高扇出
    reg [15:0] POLY_buf1, POLY_buf2;
    
    // 初始值缓冲寄存器
    reg [15:0] hFFFF_buf1, hFFFF_buf2;
    
    // 流水线结果缓冲
    reg [15:0] stage3_result_buf1, stage3_result_buf2;
    
    // 阶段选择缓冲
    reg b0_s3, b0_s3_buf1, b0_s3_buf2;
    
    // 缓冲寄存器更新逻辑
    always @(posedge clk) begin
        if (rst) begin
            POLY_buf1 <= POLY_VAL;
            POLY_buf2 <= POLY_VAL;
            hFFFF_buf1 <= 16'hFFFF;
            hFFFF_buf2 <= 16'hFFFF;
        end else begin
            POLY_buf1 <= POLY_VAL;
            POLY_buf2 <= POLY_VAL;
            hFFFF_buf1 <= 16'hFFFF;
            hFFFF_buf2 <= 16'hFFFF;
        end
    end
    
    // 流水线阶段1: 处理高4位数据位
    always @(posedge clk) begin
        if (rst) begin
            crc_reg <= 16'hFFFF;
            data_bits_s1 <= 4'b0000;
            valid_s1 <= 1'b0;
        end else begin
            if (data_valid) begin
                crc_reg <= hFFFF_buf1; // 使用缓冲的初始值
                data_bits_s1 <= data_in[7:4]; // 存储高4位用于后续阶段
                valid_s1 <= 1'b1;
            end else begin
                valid_s1 <= 1'b0;
            end
        end
    end
    
    // 流水线阶段2: 处理第一位数据
    always @(posedge clk) begin
        if (rst) begin
            stage1_result <= 16'hFFFF;
            data_bits_s2 <= 4'b0000;
            valid_s2 <= 1'b0;
        end else if (valid_s1) begin
            stage1_result <= {crc_reg[14:0], 1'b0} ^ ((crc_reg[15] ^ data_bits_s1[3]) ? POLY_buf1 : 16'h0);
            data_bits_s2 <= data_bits_s1[2:0]; // 将剩余位传递到下一阶段
            valid_s2 <= valid_s1;
        end else begin
            valid_s2 <= 1'b0;
        end
    end
    
    // 流水线阶段3: 处理第二位数据
    always @(posedge clk) begin
        if (rst) begin
            stage2_result <= 16'hFFFF;
            data_bits_s3 <= 3'b000;
            valid_s3 <= 1'b0;
        end else if (valid_s2) begin
            stage2_result <= {stage1_result[14:0], 1'b0} ^ ((stage1_result[15] ^ data_bits_s2[2]) ? POLY_buf2 : 16'h0);
            data_bits_s3 <= data_bits_s2[1:0]; // 将剩余位传递到下一阶段
            valid_s3 <= valid_s2;
        end else begin
            valid_s3 <= 1'b0;
        end
    end
    
    // 数据位缓冲更新 - 减少data_bits_s3的扇出
    always @(posedge clk) begin
        if (rst) begin
            data_bits_s3_buf1 <= 3'b000;
            data_bits_s3_buf2 <= 3'b000;
            b0_s3 <= 1'b0;
            b0_s3_buf1 <= 1'b0;
            b0_s3_buf2 <= 1'b0;
        end else if (valid_s3) begin
            data_bits_s3_buf1 <= data_bits_s3;
            data_bits_s3_buf2 <= data_bits_s3;
            b0_s3 <= data_bits_s3[0];
            b0_s3_buf1 <= data_bits_s3[0];
            b0_s3_buf2 <= data_bits_s3[0];
        end
    end
    
    // 流水线阶段4: 处理第三位数据
    always @(posedge clk) begin
        if (rst) begin
            stage3_result <= 16'hFFFF;
            stage3_result_buf1 <= 16'hFFFF;
            stage3_result_buf2 <= 16'hFFFF;
            valid_s4 <= 1'b0;
        end else if (valid_s3) begin
            stage3_result <= {stage2_result[14:0], 1'b0} ^ ((stage2_result[15] ^ data_bits_s3_buf1[1]) ? POLY_buf1 : 16'h0);
            // 立即缓冲stage3_result
            stage3_result_buf1 <= {stage2_result[14:0], 1'b0} ^ ((stage2_result[15] ^ data_bits_s3_buf1[1]) ? POLY_buf1 : 16'h0);
            stage3_result_buf2 <= {stage2_result[14:0], 1'b0} ^ ((stage2_result[15] ^ data_bits_s3_buf1[1]) ? POLY_buf1 : 16'h0);
            valid_s4 <= valid_s3;
        end else begin
            valid_s4 <= 1'b0;
        end
    end
    
    // 流水线阶段5: 处理第四位数据和输出结果
    always @(posedge clk) begin
        if (rst) begin
            stage4_result <= 16'hFFFF;
            crc_out <= 16'hFFFF;
            crc_valid <= 1'b0;
        end else if (valid_s4) begin
            // 使用缓冲的stage3_result和数据位
            stage4_result <= {stage3_result_buf1[14:0], 1'b0} ^ ((stage3_result_buf1[15] ^ b0_s3_buf1) ? POLY_buf2 : 16'h0);
            crc_out <= {stage3_result_buf2[14:0], 1'b0} ^ ((stage3_result_buf2[15] ^ b0_s3_buf2) ? POLY_buf2 : 16'h0);
            crc_valid <= 1'b1;
        end else begin
            crc_valid <= 1'b0;
        end
    end
endmodule