//SystemVerilog
// 顶层模块
module rom_parity #(
    parameter BITS = 12
)(
    input [7:0] addr,
    output [BITS-1:0] data
);
    // 内部连线
    wire [BITS-2:0] data_without_parity;
    wire parity_bit;
    wire [BITS-2:0] sub_result;
    wire borrow;

    // 实例化存储子模块
    rom_memory #(
        .DATA_WIDTH(BITS-1)
    ) memory_unit (
        .addr(addr),
        .data_out(data_without_parity)
    );

    // 条件求和减法算法实现
    assign {borrow, sub_result} = {1'b0, data_without_parity} - 1'b1; // 示例减去1

    // 实例化奇偶校验子模块
    parity_generator #(
        .DATA_WIDTH(BITS-1)
    ) parity_unit (
        .data_in(sub_result),
        .parity_out(parity_bit)
    );

    // 输出组合
    assign data = {parity_bit, sub_result};
endmodule

// 存储子模块
module rom_memory #(
    parameter DATA_WIDTH = 11
)(
    input [7:0] addr,
    output [DATA_WIDTH-1:0] data_out
);
    // 声明内存
    reg [DATA_WIDTH-1:0] mem [0:255];

    // 示例初始化
    initial begin
        // 将一些示例值设置为具体值用于综合
        mem[0] = 11'b10101010101;
        mem[1] = 11'b01010101010;
        // $readmemb("parity_data.bin", mem); // 仿真中使用
    end

    // 输出数据
    assign data_out = mem[addr];
endmodule

// 奇偶校验子模块
module parity_generator #(
    parameter DATA_WIDTH = 11
)(
    input [DATA_WIDTH-1:0] data_in,
    output parity_out
);
    // 计算奇偶校验位
    assign parity_out = ^data_in;
endmodule