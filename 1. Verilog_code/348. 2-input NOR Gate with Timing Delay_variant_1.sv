//SystemVerilog
// 顶层模块：结构化流水线2输入NOR门，分为逻辑阶段和延时缓冲阶段
module nor2_delay (
    input  wire A,
    input  wire B,
    output wire Y
);
    // 第一阶段：输入寄存器
    reg stage1_a;
    reg stage1_b;

    // 第二阶段：NOR逻辑寄存器
    reg stage2_nor;

    // 第三阶段：延时缓冲寄存器（输出寄存器）
    reg stage3_out;

    // 时钟信号假设为外部全局信号
    wire clk;
    assign clk = 1'b1; // 若需要外部时钟，请将此行替换为端口

    // Stage 1: 输入锁存A
    always @(posedge clk) begin
        stage1_a <= A;
    end

    // Stage 1: 输入锁存B
    always @(posedge clk) begin
        stage1_b <= B;
    end

    // Stage 2: NOR逻辑运算
    always @(posedge clk) begin
        stage2_nor <= ~(stage1_a | stage1_b);
    end

    // Stage 3: 延时缓冲（使用参数化延时模块）
    delay_buffer #(.DELAY(5)) u_delay_buffer (
        .clk        (clk),
        .in_signal  (stage2_nor),
        .out_signal (stage3_out)
    );

    // 输出锁存
    assign Y = stage3_out;

endmodule

// 子模块：通用延时缓冲器，带同步寄存器链
module delay_buffer #(
    parameter DELAY = 1
) (
    input  wire clk,
    input  wire in_signal,
    output wire out_signal
);
    // 使用寄存器链实现参数化延时
    reg [DELAY:0] buffer_chain;

    integer j;
    // Stage 1: 输入采样
    always @(posedge clk) begin
        buffer_chain[0] <= in_signal;
    end

    // Stage 2: 寄存器链级联
    genvar k;
    generate
        for (k = 1; k <= DELAY; k = k + 1) begin : delay_chain
            always @(posedge clk) begin
                buffer_chain[k] <= buffer_chain[k-1];
            end
        end
    endgenerate

    assign out_signal = buffer_chain[DELAY];
endmodule