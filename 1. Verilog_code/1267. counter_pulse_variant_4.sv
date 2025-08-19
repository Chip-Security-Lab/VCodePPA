//SystemVerilog
// 顶层模块
module counter_pulse #(
    parameter CYCLE = 10
) (
    input  logic clk,
    input  logic rst,
    output logic pulse
);
    // 内部信号
    logic [$clog2(CYCLE)-1:0] count_value;
    logic count_terminal;
    
    // 子模块实例化
    counter_core #(
        .CYCLE(CYCLE)
    ) counter_unit (
        .clk           (clk),
        .rst           (rst),
        .count_value   (count_value),
        .count_terminal(count_terminal)
    );
    
    pulse_generator pulse_gen_unit (
        .clk           (clk),
        .rst           (rst),
        .count_terminal(count_terminal),
        .pulse         (pulse)
    );
endmodule

// 计数器核心子模块
module counter_core #(
    parameter CYCLE = 10
) (
    input  logic clk,
    input  logic rst,
    output logic [$clog2(CYCLE)-1:0] count_value,
    output logic count_terminal
);
    // 本地参数
    localparam COUNT_WIDTH = $clog2(CYCLE);
    localparam COUNT_MAX = CYCLE - 1;
    
    // 计数逻辑
    always_ff @(posedge clk) begin
        if (rst) begin
            count_value <= '0;
        end else if (count_terminal) begin
            count_value <= '0;
        end else begin
            count_value <= count_value + 1'b1;
        end
    end
    
    // 终止计数检测
    assign count_terminal = (count_value == COUNT_MAX);
endmodule

// 脉冲生成器子模块
module pulse_generator (
    input  logic clk,
    input  logic rst,
    input  logic count_terminal,
    output logic pulse
);
    // 脉冲生成逻辑
    always_ff @(posedge clk) begin
        if (rst) begin
            pulse <= 1'b0;
        end else begin
            pulse <= count_terminal;
        end
    end
endmodule