//SystemVerilog
module gray2bin_unit #(parameter DATA_WIDTH = 8) (
    input  [DATA_WIDTH-1:0] gray_data,
    output [DATA_WIDTH-1:0] binary_data
);
    // 条件求和方式实现格雷码转二进制
    wire [DATA_WIDTH-1:0] carry_chain;
    wire [DATA_WIDTH-1:0] sum_result;
    
    // 初始化最高位
    assign carry_chain[DATA_WIDTH-1] = gray_data[DATA_WIDTH-1];
    assign sum_result[DATA_WIDTH-1] = gray_data[DATA_WIDTH-1];
    
    // 使用条件求和链式实现
    genvar i;
    generate
        for (i = DATA_WIDTH-2; i >= 0; i = i - 1) begin: sum_chain
            // 传播进位信号
            assign carry_chain[i] = carry_chain[i+1];
            // 计算当前位的结果(XOR操作等同于不进位加法)
            assign sum_result[i] = gray_data[i] ^ carry_chain[i+1];
        end
    endgenerate
    
    // 最终输出结果
    assign binary_data = sum_result;
endmodule