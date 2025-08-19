//SystemVerilog
module string_valid_xnor (
    input wire        clk,        // 添加时钟输入
    input wire        rst_n,      // 添加复位信号
    input wire        a_valid,    // 输入A有效信号
    input wire        b_valid,    // 输入B有效信号
    input wire [7:0]  data_a,     // 输入数据A
    input wire [7:0]  data_b,     // 输入数据B
    output reg [7:0]  out         // 输出结果
);
    // 流水线阶段寄存器定义
    reg         input_valid_r;    // 输入有效寄存器
    reg [7:0]   data_a_r;         // 数据A寄存器
    reg [7:0]   data_b_r;         // 数据B寄存器
    reg [7:0]   xnor_result;      // XNOR结果寄存器
    
    // 乘法器相关寄存器与信号
    reg [7:0]   multiplicand;     // 被乘数
    reg [7:0]   multiplier;       // 乘数
    reg [15:0]  product;          // 乘积结果
    reg [3:0]   counter;          // 循环计数器
    reg         mult_busy;        // 乘法计算进行中标志
    reg         mult_done;        // 乘法计算完成标志
    reg [7:0]   mult_result;      // 乘法结果
    
    // 第一阶段：输入寄存器和控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_valid_r <= 1'b0;
            data_a_r <= 8'b0;
            data_b_r <= 8'b0;
            mult_busy <= 1'b0;
            counter <= 4'b0;
        end else begin
            // 捕获输入数据
            input_valid_r <= a_valid && b_valid;
            
            if (a_valid && b_valid && !mult_busy) begin
                data_a_r <= data_a;
                data_b_r <= data_b;
                mult_busy <= 1'b1;
                counter <= 4'b0;
            end else if (mult_busy && counter < 8) begin
                counter <= counter + 1'b1;
            end else if (mult_busy && counter == 8) begin
                mult_busy <= 1'b0;
            end
        end
    end
    
    // 第二阶段：XNOR计算 - 独立的组合逻辑路径
    always @(*) begin
        xnor_result = ~(data_a_r ^ data_b_r);
    end
    
    // 第三阶段：乘法计算逻辑 - 流水线化的乘法器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            multiplicand <= 8'b0;
            multiplier <= 8'b0;
            product <= 16'b0;
            mult_done <= 1'b0;
        end else begin
            if (input_valid_r && !mult_busy) begin
                // 乘法器初始化
                multiplicand <= data_a_r;
                multiplier <= data_b_r;
                product <= 16'b0;
                mult_done <= 1'b0;
            end else if (mult_busy) begin
                // 逐位乘法操作
                if (multiplier[0]) begin
                    product <= product + {8'b0, multiplicand};
                end
                
                multiplicand <= multiplicand << 1;
                multiplier <= multiplier >> 1;
                
                // 设置乘法完成标志
                if (counter == 7) begin
                    mult_done <= 1'b1;
                end
            end
        end
    end
    
    // 第四阶段：保存乘法结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_result <= 8'b0;
        end else if (mult_done) begin
            mult_result <= product[7:0];
        end
    end
    
    // 最终输出阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'b0;
        end else if (input_valid_r) begin
            // 注意：此处我们使用XNOR结果作为输出，与原代码功能一致
            out <= xnor_result;
        end else if (!input_valid_r) begin
            out <= 8'b0;
        end
    end
    
endmodule