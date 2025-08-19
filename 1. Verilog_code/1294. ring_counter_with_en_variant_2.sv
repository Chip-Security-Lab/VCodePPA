//SystemVerilog
// 顶层模块
module ring_counter_with_en (
    input  logic       clk,    // 时钟信号
    input  logic       en,     // 使能信号
    input  logic       rst,    // 复位信号
    output logic [3:0] q       // 输出计数值
);
    // 内部信号定义
    logic       en_sync;       // 同步后的使能信号
    logic       rst_sync;      // 同步后的复位信号
    logic [3:0] q_internal;    // 内部计数值

    // 实例化输入同步子模块
    input_synchronizer u_input_synchronizer (
        .clk      (clk),
        .en_in    (en),
        .rst_in   (rst),
        .en_out   (en_sync),
        .rst_out  (rst_sync)
    );

    // 实例化环形计数器核心子模块
    counter_core u_counter_core (
        .clk      (clk),
        .en       (en_sync),
        .rst      (rst_sync),
        .q_out    (q_internal)
    );

    // 实例化输出缓冲寄存器子模块
    output_register u_output_register (
        .clk      (clk),
        .q_in     (q_internal),
        .q_out    (q)
    );
endmodule

// 输入同步子模块 - 处理使能和复位信号的同步
module input_synchronizer (
    input  logic       clk,     // 时钟信号
    input  logic       en_in,   // 使能输入
    input  logic       rst_in,  // 复位输入
    output logic       en_out,  // 同步后的使能输出
    output logic       rst_out  // 同步后的复位输出
);
    // 简单的单周期同步逻辑
    always_ff @(posedge clk) begin
        en_out  <= en_in;
        rst_out <= rst_in;
    end
endmodule

// 环形计数器核心子模块 - 实现环形计数功能
module counter_core (
    input  logic       clk,     // 时钟信号
    input  logic       en,      // 使能信号
    input  logic       rst,     // 复位信号
    output logic [3:0] q_out    // 计数器输出
);
    // 计数器状态更新逻辑
    always_ff @(posedge clk) begin
        // 使用{rst,en}作为case语句的条件选择变量
        case({rst, en})
            2'b10,
            2'b11:   q_out <= 4'b0001;  // 复位优先
            2'b01:   q_out <= {q_out[0], q_out[3:1]};  // 仅使能时循环移位
            2'b00:   q_out <= q_out;    // 保持当前状态
            default: q_out <= 4'b0001;  // 安全默认值
        endcase
    end
endmodule

// 输出寄存器子模块 - 缓冲输出值
module output_register (
    input  logic       clk,     // 时钟信号
    input  logic [3:0] q_in,    // 输入数据
    output logic [3:0] q_out    // 缓冲后的输出
);
    // 输出缓冲逻辑
    always_ff @(posedge clk) begin
        q_out <= q_in;  // 注册输出
    end
endmodule