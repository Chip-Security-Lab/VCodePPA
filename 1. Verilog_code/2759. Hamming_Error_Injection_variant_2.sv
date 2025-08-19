//SystemVerilog
module Hamming_Error_Injection(
    input clk,
    input rst_n,                 // 复位信号
    input valid_in,              // 输入数据有效信号
    output reg ready_out,        // 输出就绪信号
    input [3:0] error_position,  // 错误位置
    input error_en,              // 错误注入使能
    input [7:0] clean_code,      // 输入干净的码字
    output reg [7:0] corrupted_code, // 输出被错误污染的码字
    output reg valid_out,        // 输出数据有效信号
    input ready_in               // 下游模块就绪信号
);

    // 内部状态和寄存器
    reg [7:0] data_reg;
    reg error_en_reg;
    reg [3:0] error_position_reg;
    reg processing;
    
    // 流水线寄存器 - 用于关键路径切割
    reg [7:0] clean_code_reg;
    reg [7:0] error_mask;
    reg compute_stage;
    
    // 错误位掩码生成逻辑
    wire [7:0] position_mask = (1'b1 << error_position);

    // 握手控制和数据处理逻辑 - 采用两阶段流水线处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有寄存器
            corrupted_code <= 8'b0;
            data_reg <= 8'b0;
            error_en_reg <= 1'b0;
            error_position_reg <= 4'b0;
            valid_out <= 1'b0;
            ready_out <= 1'b1;
            processing <= 1'b0;
            
            // 复位流水线寄存器
            clean_code_reg <= 8'b0;
            error_mask <= 8'b0;
            compute_stage <= 1'b0;
        end else begin
            // 第一阶段 - 输入握手并准备错误掩码
            if (valid_in && ready_out && !processing) begin
                // 采样输入数据到第一阶段流水线寄存器
                clean_code_reg <= clean_code;
                error_en_reg <= error_en;
                error_position_reg <= error_position;
                
                // 生成错误掩码，将关键路径的计算分离
                error_mask <= error_en ? position_mask : 8'b0;
                
                ready_out <= 1'b0;  // 不再接受新数据
                processing <= 1'b1;
                compute_stage <= 1'b1;  // 启动计算阶段
            end
            
            // 第二阶段 - 完成错误注入计算
            if (compute_stage) begin
                // 使用预先计算的错误掩码应用到数据上
                corrupted_code <= clean_code_reg ^ error_mask;
                valid_out <= 1'b1;  // 输出数据有效
                compute_stage <= 1'b0;  // 计算阶段完成
            end
            
            // 输出握手逻辑
            if (valid_out && ready_in) begin
                valid_out <= 1'b0;  // 数据已被接收
                ready_out <= 1'b1;  // 可以接收新数据
                processing <= 1'b0;
            end
        end
    end

endmodule