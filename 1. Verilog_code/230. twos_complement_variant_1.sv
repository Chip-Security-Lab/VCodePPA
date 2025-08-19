//SystemVerilog
module twos_complement (
    input signed [3:0] value,
    output reg [3:0] absolute,
    output [3:0] negative
);
    wire [3:0] inverted;
    wire [3:0] complement;
    wire carry;
    
    // 取负值的条件求和实现
    assign inverted = ~value;                    // 按位取反
    assign {carry, complement} = inverted + 4'd1; // 加1得到补码
    
    // 计算绝对值
    always @(*) begin
        if (value[3] == 0) begin  // 正数或零
            absolute = value;
        end
        else begin                // 负数
            absolute = complement;
        end
    end
    
    // 计算负值
    assign negative = (value == 4'd0) ? 4'd0 : // 如果输入为0，结果为0
                     (value[3]) ? value :      // 如果输入已经是负数，保持不变
                     complement;               // 如果是正数，取其补码
endmodule