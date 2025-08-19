//SystemVerilog
module DivRem(
    input [7:0] num, den,
    output reg [7:0] q, r
);
    // 内部信号声明
    reg is_den_zero;
    reg is_den_one;
    reg is_num_lt_den;
    reg [7:0] div_result;
    reg [7:0] mod_result;

    // 检测特殊条件
    always @(*) begin
        // 检测除数是否为零
        is_den_zero = (den == 8'h0);
        // 检测除数是否为1
        is_den_one = (den == 8'h1);
        // 检测被除数是否小于除数
        is_num_lt_den = (num < den);
    end

    // 计算标准除法和求模结果
    always @(*) begin
        if (!is_den_zero) begin
            div_result = num / den;
            mod_result = num % den;
        end else begin
            div_result = 8'hFF;
            mod_result = num;
        end
    end

    // 根据条件选择最终输出
    always @(*) begin
        if (is_den_zero) begin
            // 除零保护
            q = 8'hFF;
            r = num;
        end else if (is_den_one) begin
            // 除数为1的特殊情况
            q = num;
            r = 8'h0;
        end else if (is_num_lt_den) begin
            // 被除数小于除数的特殊情况
            q = 8'h0;
            r = num;
        end else begin
            // 标准情况
            q = div_result;
            r = mod_result;
        end
    end
endmodule