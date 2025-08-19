//SystemVerilog
module MedianFilter #(parameter WIDTH=8) (
    input [WIDTH-1:0] a, b, c,
    output reg [WIDTH-1:0] med
);

    always @(*) begin
        // 优化后的中值查找逻辑
        // 通过位级操作直接比较三个值并选择中间值
        if ((a <= b && b <= c) || (c <= b && b <= a))
            med = b;
        else if ((b <= a && a <= c) || (c <= a && a <= b))
            med = a;
        else
            med = c;
    end
endmodule