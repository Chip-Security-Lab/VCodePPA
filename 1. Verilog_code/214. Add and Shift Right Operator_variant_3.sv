//SystemVerilog
module add_signed_divide (
    input wire clk,                    // 添加时钟输入
    input wire rst_n,                  // 添加复位输入
    input wire signed [7:0] a,         // 输入a
    input wire signed [7:0] b,         // 输入b
    input wire signed [7:0] c,         // 输入c
    input wire valid_in,               // 输入有效信号
    output reg signed [15:0] sum,      // 加法结果输出
    output reg signed [7:0] quotient,  // 除法结果输出
    output reg valid_out               // 输出有效信号
);
    // 内部寄存器 - 输入流水线寄存器
    reg signed [7:0] a_reg, b_reg, c_reg;
    reg valid_stage1;
    
    // 加法计算内部寄存器
    reg signed [15:0] sum_temp;
    
    // 除法计算内部寄存器
    reg signed [7:0] quotient_temp;
    reg valid_stage2;
    
    // 输入流水线级 - 寄存器输入值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            c_reg <= 8'b0;
            valid_stage1 <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            c_reg <= c;
            valid_stage1 <= valid_in;
        end
    end
    
    // 运算流水线级 - 执行加法和除法操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_temp <= 16'b0;
            quotient_temp <= 8'b0;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                // 加法操作路径
                sum_temp <= a_reg + c_reg;
                
                // 除法操作路径 (避免除零)
                quotient_temp <= (b_reg != 0) ? a_reg / b_reg : 8'b0;
                
                valid_stage2 <= valid_stage1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 输出流水线级 - 更新输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 16'b0;
            quotient <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            if (valid_stage2) begin
                sum <= sum_temp;
                quotient <= quotient_temp;
                valid_out <= valid_stage2;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end
    
endmodule