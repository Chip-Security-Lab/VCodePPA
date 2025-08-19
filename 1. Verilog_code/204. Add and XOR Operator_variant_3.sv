//SystemVerilog
module multiply_divide_operator (
    input clk,                 // 系统时钟
    input rst_n,               // 低电平有效复位
    input [7:0] a,             // 操作数A
    input [7:0] b,             // 操作数B
    input valid_in,            // 输入数据有效信号
    output ready_in,           // 输入就绪信号
    output [15:0] product,     // 乘法结果
    output [7:0] quotient,     // 除法结果
    output [7:0] remainder,    // 余数结果
    output valid_out,          // 输出数据有效信号
    input ready_out            // 接收方就绪信号
);

    // 内部寄存器
    reg [15:0] product_reg;
    reg [7:0] quotient_reg;
    reg [7:0] remainder_reg;
    reg valid_out_reg;
    reg computing;
    
    // 状态控制
    assign ready_in = !computing || (valid_out_reg && ready_out);
    assign valid_out = valid_out_reg;
    
    // 输出赋值
    assign product = product_reg;
    assign quotient = quotient_reg;
    assign remainder = remainder_reg;
    
    // 主状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product_reg <= 16'b0;
            quotient_reg <= 8'b0;
            remainder_reg <= 8'b0;
            valid_out_reg <= 1'b0;
            computing <= 1'b0;
        end else begin
            // 处理新数据
            if (valid_in && ready_in) begin
                computing <= 1'b1;
                valid_out_reg <= 1'b0;
                
                // 计算结果
                product_reg <= a * b;
                
                // 避免除零错误
                if (b != 0) begin
                    quotient_reg <= a / b;
                    remainder_reg <= a % b;
                end else begin
                    quotient_reg <= 8'hFF; // 除零错误标记
                    remainder_reg <= a;    // 余数等于被除数
                end
            end
            
            // 计算完成
            if (computing) begin
                valid_out_reg <= 1'b1;
                computing <= 1'b0;
            end
            
            // 完成数据传输
            if (valid_out_reg && ready_out) begin
                valid_out_reg <= 1'b0;
            end
        end
    end
    
endmodule