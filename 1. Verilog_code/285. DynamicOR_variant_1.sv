//SystemVerilog
module DynamicOR(
    input wire clk,          // 时钟信号
    input wire rst_n,        // 复位信号
    input wire [2:0] shift,  // 移位量
    input wire [31:0] vec1,  // 输入向量1
    input wire [31:0] vec2,  // 输入向量2
    output wire [31:0] res   // 结果输出
);
    // 时钟缓冲树
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // 复位信号缓冲
    wire rst_n_buf1, rst_n_buf2, rst_n_buf3;
    
    // 时钟缓冲分配
    assign clk_buf1 = clk;  // 用于阶段1的时钟
    assign clk_buf2 = clk;  // 用于阶段2的时钟
    assign clk_buf3 = clk;  // 用于阶段3的时钟
    
    // 复位缓冲分配
    assign rst_n_buf1 = rst_n;  // 用于阶段1的复位
    assign rst_n_buf2 = rst_n;  // 用于阶段2的复位
    assign rst_n_buf3 = rst_n;  // 用于阶段3的复位
    
    // 数据流分段处理寄存器
    reg [31:0] vec1_reg, vec2_reg;
    reg [2:0] shift_reg;
    reg [31:0] shifted_data;
    reg [31:0] result_reg;
    
    // 向量1缓冲，减少扇出负载
    reg [31:0] vec1_buf;
    
    // 阶段1: 数据输入寄存
    always @(posedge clk_buf1 or negedge rst_n_buf1) begin
        if (!rst_n_buf1) begin
            vec1_reg <= 32'b0;
            vec2_reg <= 32'b0;
            shift_reg <= 3'b0;
            vec1_buf <= 32'b0;
        end else begin
            vec1_reg <= vec1;
            vec2_reg <= vec2;
            shift_reg <= shift;
            vec1_buf <= vec1;  // 创建vec1的缓冲副本
        end
    end
    
    // 移位量缓冲寄存器，减少扇出
    reg [2:0] shift_buf;
    
    // 阶段1.5: 缓冲移位控制信号
    always @(posedge clk_buf1 or negedge rst_n_buf1) begin
        if (!rst_n_buf1) begin
            shift_buf <= 3'b0;
        end else begin
            shift_buf <= shift_reg;
        end
    end
    
    // 阶段2: 执行移位操作
    always @(posedge clk_buf2 or negedge rst_n_buf2) begin
        if (!rst_n_buf2) begin
            shifted_data <= 32'b0;
        end else begin
            // 使用缓冲的移位控制信号
            shifted_data <= vec1_buf << shift_buf;
        end
    end
    
    // 阶段2.5: 缓冲移位后的数据和向量2
    reg [31:0] shifted_data_buf, vec2_reg_buf;
    
    always @(posedge clk_buf2 or negedge rst_n_buf2) begin
        if (!rst_n_buf2) begin
            shifted_data_buf <= 32'b0;
            vec2_reg_buf <= 32'b0;
        end else begin
            shifted_data_buf <= shifted_data;
            vec2_reg_buf <= vec2_reg;
        end
    end
    
    // 阶段3: 执行OR操作并输出
    always @(posedge clk_buf3 or negedge rst_n_buf3) begin
        if (!rst_n_buf3) begin
            result_reg <= 32'b0;
        end else begin
            // 使用缓冲的数据进行OR操作
            result_reg <= shifted_data_buf | vec2_reg_buf;
        end
    end
    
    // 结果输出
    assign res = result_reg;
    
endmodule