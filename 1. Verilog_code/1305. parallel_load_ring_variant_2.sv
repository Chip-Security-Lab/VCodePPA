//SystemVerilog
// Top level module
module parallel_load_ring (
    input clk,
    input valid,              // 发送方表示数据有效 (原load信号)
    input [3:0] parallel_in,  // 输入数据
    output [3:0] ring,        // 环形寄存器输出
    output ready              // 接收方表示准备好接收数据
);
    // 内部连线
    wire ctrl_busy;
    wire load_enable;
    wire shift_enable;

    // 控制单元实例
    handshake_control handshake_ctrl_inst (
        .clk(clk),
        .valid(valid),
        .ready(ready),
        .busy(ctrl_busy),
        .load_enable(load_enable),
        .shift_enable(shift_enable)
    );

    // 数据处理单元实例
    ring_register ring_reg_inst (
        .clk(clk),
        .load_enable(load_enable),
        .shift_enable(shift_enable),
        .parallel_in(parallel_in),
        .ring_out(ring)
    );

endmodule

// 握手控制子模块
module handshake_control (
    input clk,
    input valid,              // 输入握手请求
    output reg ready,         // 输出握手响应
    output reg busy,          // 忙状态指示
    output reg load_enable,   // 加载使能信号
    output reg shift_enable   // 移位使能信号
);
    // 初始化
    initial begin
        ready = 1'b1;
        busy = 1'b0;
        load_enable = 1'b0;
        shift_enable = 1'b0;
    end

    always @(posedge clk) begin
        // 默认值
        load_enable <= 1'b0;
        shift_enable <= 1'b0;

        if (valid && ready) begin
            // 握手成功，开始加载数据
            load_enable <= 1'b1;
            ready <= 1'b0;     // 数据接收后，暂时不接收新数据
            busy <= 1'b1;      // 进入忙状态
        end else if (busy) begin
            // 处于忙状态，执行移位操作
            shift_enable <= 1'b1;
            ready <= 1'b1;     // 移位后恢复ready
            busy <= 1'b0;      // 移位后退出忙状态
        end else begin
            // 空闲状态，保持ready为高
            ready <= 1'b1;
        end
    end
endmodule

// 环形寄存器子模块
module ring_register (
    input clk,
    input load_enable,        // 加载使能
    input shift_enable,       // 移位使能
    input [3:0] parallel_in,  // 并行输入数据
    output reg [3:0] ring_out // 环形寄存器输出
);
    // 初始化
    initial begin
        ring_out = 4'b0000;
    end

    always @(posedge clk) begin
        if (load_enable) begin
            // 加载并行数据
            ring_out <= parallel_in;
        end else if (shift_enable) begin
            // 执行环形移位操作: 右移加循环
            ring_out <= {ring_out[0], ring_out[3:1]};
        end
    end
endmodule