//SystemVerilog
// SystemVerilog
module twos_complement (
    input signed [3:0] value,
    output reg [3:0] absolute,
    output reg [3:0] negative
);
    // 检测负值的信号
    wire is_negative = value[3];
    wire [3:0] value_inv = ~value;
    wire [3:0] plus_one = value_inv + 4'b0001;
    
    // 使用always块替代条件运算符，实现绝对值和负值的计算
    always @(*) begin
        if (is_negative) begin
            absolute = plus_one;
            negative = value;
        end
        else begin
            absolute = value;
            negative = plus_one;
        end
    end
endmodule