//SystemVerilog
// SystemVerilog
// 顶层模块
module subtractor_8bit_generate (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] y
);
    // 参数化配置
    localparam DATA_WIDTH = 8;
    localparam GROUP_SIZE = 4;
    
    // 将8位分为两组，每组4位
    wire [GROUP_SIZE-1:0] lower_group_result;
    wire [GROUP_SIZE-1:0] upper_group_result;
    
    // 实例化低位组减法处理单元(使用补码加法实现)
    subtraction_unit #(
        .DATA_WIDTH(GROUP_SIZE)
    ) lower_group_unit (
        .minuend(a[GROUP_SIZE-1:0]),
        .subtrahend(b[GROUP_SIZE-1:0]),
        .difference(lower_group_result)
    );
    
    // 实例化高位组减法处理单元(使用补码加法实现)
    subtraction_unit #(
        .DATA_WIDTH(GROUP_SIZE)
    ) upper_group_unit (
        .minuend(a[DATA_WIDTH-1:GROUP_SIZE]),
        .subtrahend(b[DATA_WIDTH-1:GROUP_SIZE]),
        .difference(upper_group_result)
    );
    
    // 组合结果
    assign y = {upper_group_result, lower_group_result};
    
endmodule

// 可重用的减法处理单元子模块(使用补码加法实现)
module subtraction_unit #(
    parameter DATA_WIDTH = 4
)(
    input wire [DATA_WIDTH-1:0] minuend,
    input wire [DATA_WIDTH-1:0] subtrahend,
    output wire [DATA_WIDTH-1:0] difference
);
    // 对减数取反
    wire [DATA_WIDTH-1:0] complemented_subtrahend;
    
    // 实例化基本单元进行运算
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : subtraction_elements
            // 对减数的每一位取反
            complement_cell single_bit_complement (
                .bit_in(subtrahend[i]),
                .bit_out(complemented_subtrahend[i])
            );
        end
    endgenerate
    
    // 使用补码加法实现减法 (A - B = A + (~B) + 1)
    wire [DATA_WIDTH:0] temp_sum; // 额外一位用于加1和进位
    assign temp_sum = minuend + complemented_subtrahend + 1'b1;
    assign difference = temp_sum[DATA_WIDTH-1:0]; // 取低DATA_WIDTH位作为结果
endmodule

// 基础取反单元
module complement_cell (
    input wire bit_in,
    output wire bit_out
);
    // 单比特取反操作
    assign bit_out = ~bit_in;
endmodule