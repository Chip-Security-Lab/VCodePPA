//SystemVerilog
module twos_complement (
    input signed [3:0] value,
    output [3:0] absolute,
    output [3:0] negative
);
    wire [3:0] inverted_value;
    wire [3:0] complement_value;
    wire negative_flag;
    
    // 判断输入是否为负数
    assign negative_flag = value[3];
    
    // 对输入值取反
    assign inverted_value = ~value;
    
    // 取反加一得到补码
    assign complement_value = inverted_value + 4'b0001;
    
    // 根据输入符号选择合适的值作为绝对值
    assign absolute = negative_flag ? complement_value : value;
    
    // 对于负值，始终使用补码加法实现
    assign negative = ~value + 4'b0001;
endmodule