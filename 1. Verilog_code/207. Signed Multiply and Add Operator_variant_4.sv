//SystemVerilog
module signed_multiply_add (
    input wire clk,
    input wire rst_n,
    
    // Valid-Ready 握手接口 - 输入
    input wire valid_in,           // 输入数据有效信号
    output wire ready_in,          // 输入准备好接收信号
    input wire signed [7:0] a,     // 输入操作数
    input wire signed [7:0] b,     // 输入操作数
    input wire signed [7:0] c,     // 输入操作数
    
    // Valid-Ready 握手接口 - 输出
    output wire valid_out,         // 输出数据有效信号
    input wire ready_out,          // 输出方准备好接收信号
    output wire signed [15:0] result  // 计算结果
);
    // 临时变量用于存储部分积
    reg signed [15:0] partial_products[0:7];
    reg signed [15:0] mult_result;
    reg signed [15:0] result_reg;
    reg valid_out_reg;
    reg busy;
    
    // 握手逻辑
    assign ready_in = !busy || (valid_out_reg && ready_out);
    assign valid_out = valid_out_reg;
    assign result = result_reg;
    
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out_reg <= 1'b0;
            busy <= 1'b0;
            result_reg <= 16'b0;
        end else begin
            if (valid_in && ready_in) begin
                // 接收到新数据，开始计算
                busy <= 1'b1;
                
                // 实现乘法逻辑
                // 初始化部分积
                for (i = 0; i < 8; i = i + 1) begin
                    partial_products[i] = 16'b0;
                end
                
                // 计算部分积
                for (i = 0; i < 8; i = i + 1) begin
                    if (b[i] == 1'b1) begin
                        partial_products[i] = a << i;
                    end else begin
                        partial_products[i] = 16'b0;
                    end
                end
                
                // 处理符号位特殊情况
                if (b[7] == 1'b1) begin
                    partial_products[7] = -(a << 7);
                end
                
                // 累加所有部分积得到乘法结果
                mult_result = 16'b0;
                for (i = 0; i < 8; i = i + 1) begin
                    mult_result = mult_result + partial_products[i];
                end
                
                // 最终结果是乘法结果加上c
                result_reg <= mult_result + c;
                valid_out_reg <= 1'b1;
            end else if (valid_out_reg && ready_out) begin
                // 数据已被接收，清除valid标志
                valid_out_reg <= 1'b0;
                busy <= 1'b0;
            end
        end
    end
endmodule