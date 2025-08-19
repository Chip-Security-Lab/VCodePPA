//SystemVerilog
// 顶层模块
module rom_async #(parameter DATA=16, ADDR=8)(
    input [ADDR-1:0] a,
    input [7:0] minuend,
    input [7:0] subtrahend,
    output [DATA-1:0] dout,
    output [7:0] diff,
    output borrow_out
);
    // 实例化存储器子模块
    wire [DATA-1:0] mem_dout;
    memory #(DATA, ADDR) mem_inst (
        .addr(a),
        .dout(mem_dout)
    );

    // 实例化条件反相减法器模块
    wire [7:0] sub_diff;
    wire sub_borrow_out;
    conditional_inverse_subtractor sub_inst (
        .a(minuend),
        .b(subtrahend),
        .diff(sub_diff),
        .bout(sub_borrow_out)
    );

    // 输出连接
    assign dout = mem_dout;
    assign diff = sub_diff;
    assign borrow_out = sub_borrow_out;
endmodule

// 定义子模块：存储器
module memory #(parameter DATA=16, ADDR=8)(
    input [ADDR-1:0] addr,
    output [DATA-1:0] dout
);
    // 声明存储器
    reg [DATA-1:0] mem [(1<<ADDR)-1:0];

    // 读取操作
    assign dout = mem[addr];

    // 初始化内容
    initial begin
        // 示例初始化，实际使用时应替换为具体值
        mem[0] = 16'h1234;
        mem[1] = 16'h5678;
        mem[2] = 16'h9ABC;
        mem[3] = 16'hDEF0;
        // 为简化，仅初始化部分内容
        // $readmemh("init_data.hex", mem); // 仿真中使用
    end
endmodule

// 定义条件反相减法器模块 (8位)
module conditional_inverse_subtractor(
    input [7:0] a,         // 被减数
    input [7:0] b,         // 减数
    output [7:0] diff,     // 差
    output bout            // 借位输出
);
    // 内部信号
    wire [7:0] b_complement;
    wire [8:0] extended_sum;

    // 反相减数
    assign b_complement = ~b;

    // 执行加法: a + (~b) + 1 (等效于 a - b)
    assign extended_sum = a + b_complement + 8'b1;

    // 提取结果和借位
    assign diff = extended_sum[7:0];
    assign bout = ~extended_sum[8]; // 借位是进位的反
endmodule