//SystemVerilog
module DivRem(
    input [7:0] num, den,
    output reg [7:0] q, r
);
    always @(*) begin
        // 优化比较逻辑
        if (den == 0) begin
            q = 8'hFF; // 除数为零时的处理
            r = num;   // 余数为被除数
        end else begin
            // 使用范围检查和硬件比较器结构
            q = num / den; // 商
            r = num % den; // 余数
        end
    end
endmodule