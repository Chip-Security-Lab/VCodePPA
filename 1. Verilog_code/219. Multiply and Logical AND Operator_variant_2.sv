//SystemVerilog
module multiply_and_operator (
    input clk,                    // 时钟信号
    input rst_n,                  // 复位信号，低电平有效
    
    input [7:0] a,               // 输入数据 a
    input [7:0] b,               // 输入数据 b
    input valid_in,              // 输入数据有效信号
    output reg ready_in,         // 输入准备好接收信号
    
    output reg [15:0] product,   // 乘法结果
    output reg [7:0] and_result, // 与操作结果
    output reg valid_out,        // 输出数据有效信号
    input ready_out              // 下游准备好接收信号
);
    
    // 内部寄存器
    reg [7:0] a_reg, b_reg;
    reg calculating;
    
    // 为高扇出信号b添加缓冲寄存器
    reg [7:0] b0_buf1, b0_buf2;
    reg [7:0] b1_buf1, b1_buf2;
    
    // 状态机控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_in <= 1'b1;          // 复位时准备好接收数据
            valid_out <= 1'b0;         // 复位时输出无效
            calculating <= 1'b0;
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            b0_buf1 <= 8'b0;
            b0_buf2 <= 8'b0;
            b1_buf1 <= 8'b0;
            b1_buf2 <= 8'b0;
            product <= 16'b0;
            and_result <= 8'b0;
        end else begin
            // 输入握手处理
            if (ready_in && valid_in) begin
                a_reg <= a;            // 锁存输入数据
                b_reg <= b;
                
                // 更新b信号的缓冲寄存器
                b0_buf1 <= b[3:0];     // 低4位缓冲
                b1_buf1 <= b[7:4];     // 高4位缓冲
                
                ready_in <= 1'b0;      // 停止接收新数据
                calculating <= 1'b1;   // 进入计算状态
            end
            
            // 更新第二级缓冲
            b0_buf2 <= b0_buf1;
            b1_buf2 <= b1_buf1;
            
            // 计算处理
            if (calculating) begin
                // 使用缓冲后的b信号进行乘法和与操作
                // 将b重组为{b1_buf1, b0_buf2}和{b1_buf2, b0_buf1}以分散负载
                product <= a_reg * {b1_buf1, b0_buf2};  
                and_result <= a_reg & {b1_buf2, b0_buf1};
                calculating <= 1'b0;           // 计算完成
                valid_out <= 1'b1;             // 输出数据有效
            end
            
            // 输出握手处理
            if (valid_out && ready_out) begin
                valid_out <= 1'b0;             // 清除输出有效信号
                ready_in <= 1'b1;              // 准备接收下一组数据
            end
        end
    end
    
endmodule