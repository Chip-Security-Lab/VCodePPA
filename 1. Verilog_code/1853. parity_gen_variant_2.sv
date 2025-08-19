//SystemVerilog
// 顶层模块 - 组织功能子模块的连接
module parity_gen #(parameter WIDTH=8, POS="LSB") (
    input [WIDTH-1:0] data_in,
    output [WIDTH:0] data_out
);
    // 内部信号声明
    wire parity_bit;
    
    // 计算奇偶校验位的子模块实例化
    parity_calculator #(
        .WIDTH(WIDTH)
    ) parity_calc_inst (
        .data(data_in),
        .parity(parity_bit)
    );
    
    // 位置放置子模块实例化
    data_formatter #(
        .WIDTH(WIDTH),
        .POS(POS)
    ) data_format_inst (
        .data_in(data_in),
        .parity_bit(parity_bit),
        .data_out(data_out)
    );
endmodule

// 奇偶校验位计算子模块
module parity_calculator #(parameter WIDTH=8) (
    input [WIDTH-1:0] data,
    output parity
);
    // 计算奇偶校验位 - 使用补码加法实现
    wire [WIDTH-1:0] ones_complement;
    wire [WIDTH-1:0] twos_complement;
    wire [WIDTH:0] sum_result;
    
    // 计算1的补码
    assign ones_complement = ~data;
    
    // 计算2的补码
    assign twos_complement = ones_complement + 1'b1;
    
    // 使用补码加法计算奇偶性
    assign sum_result = data + twos_complement;
    assign parity = sum_result[WIDTH];
endmodule

// 数据格式化子模块 - 根据POS参数放置奇偶校验位
module data_formatter #(
    parameter WIDTH=8,
    parameter POS="MSB"
) (
    input [WIDTH-1:0] data_in,
    input parity_bit,
    output reg [WIDTH:0] data_out
);
    // 根据POS参数确定奇偶校验位的位置
    always @(*) begin
        if (POS == "MSB") 
            data_out = {parity_bit, data_in};
        else
            data_out = {data_in, parity_bit};
    end
endmodule