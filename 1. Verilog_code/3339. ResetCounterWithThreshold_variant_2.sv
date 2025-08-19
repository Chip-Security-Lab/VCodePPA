//SystemVerilog
// 顶层模块：计数器复位检测（层次化结构）
module ResetCounterWithThreshold #(
    parameter THRESHOLD = 10
) (
    input  wire        clk,
    input  wire        rst_n,
    output wire        reset_detected
);

    // 内部信号定义
    wire [3:0] counter_value;
    wire [3:0] counter_buf1_out;
    wire [3:0] counter_buf2_out;
    wire       reset_detected_core;
    
    // 计数器单元
    CounterUnit #(
        .THRESHOLD(THRESHOLD)
    ) u_counter_unit (
        .clk        (clk),
        .rst_n      (rst_n),
        .count_out  (counter_value)
    );
    
    // 第一级缓冲寄存器
    BufferReg #(
        .WIDTH  (4)
    ) u_buffer_reg1 (
        .clk        (clk),
        .rst_n      (rst_n),
        .din        (counter_value),
        .dout       (counter_buf1_out)
    );
    
    // 第二级缓冲寄存器
    BufferReg #(
        .WIDTH  (4)
    ) u_buffer_reg2 (
        .clk        (clk),
        .rst_n      (rst_n),
        .din        (counter_buf1_out),
        .dout       (counter_buf2_out)
    );
    
    // 检测单元
    ResetDetectLogic #(
        .THRESHOLD(THRESHOLD)
    ) u_reset_detect_logic (
        .clk            (clk),
        .rst_n          (rst_n),
        .counter_in     (counter_buf2_out),
        .reset_detected (reset_detected_core)
    );
    
    // 输出缓冲单元
    OutputBuffer u_output_buffer (
        .clk            (clk),
        .rst_n          (rst_n),
        .din            (reset_detected_core),
        .dout           (reset_detected)
    );

endmodule

// 子模块：计数器单元
// 功能：在复位后，每个时钟周期计数，计数值不超过THRESHOLD
module CounterUnit #(
    parameter THRESHOLD = 10
) (
    input  wire        clk,
    input  wire        rst_n,
    output reg  [3:0]  count_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count_out <= 4'b0;
        else if (count_out < THRESHOLD)
            count_out <= count_out + 1'b1;
    end
endmodule

// 子模块：通用缓冲寄存器
// 功能：同步数据缓冲，用于扇出或时序平衡
module BufferReg #(
    parameter WIDTH = 4
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] din,
    output reg  [WIDTH-1:0] dout
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout <= {WIDTH{1'b0}};
        else
            dout <= din;
    end
endmodule

// 子模块：复位检测逻辑
// 功能：检测计数达到阈值，产生复位检测信号
module ResetDetectLogic #(
    parameter THRESHOLD = 10
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] counter_in,
    output reg        reset_detected
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reset_detected <= 1'b0;
        else
            reset_detected <= (counter_in >= THRESHOLD);
    end
endmodule

// 子模块：输出缓冲
// 功能：对复位检测信号进行一级同步缓冲，改善时序与负载
module OutputBuffer (
    input  wire clk,
    input  wire rst_n,
    input  wire din,
    output reg  dout
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout <= 1'b0;
        else
            dout <= din;
    end
endmodule