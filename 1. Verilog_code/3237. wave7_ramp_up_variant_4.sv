//SystemVerilog
// 顶层模块 - 斜坡波形生成器
module wave7_ramp_up #(
    parameter WIDTH = 8,
    parameter STEP  = 2
)(
    input  wire             clk,
    input  wire             rst,
    output wire [WIDTH-1:0] wave_out
);
    // 内部连线
    wire [WIDTH-1:0] counter_value;
    
    // 实例化计数器子模块
    ramp_counter #(
        .WIDTH(WIDTH),
        .STEP(STEP)
    ) u_ramp_counter (
        .clk          (clk),
        .rst          (rst),
        .counter_out  (counter_value)
    );
    
    // 实例化输出驱动子模块
    output_driver #(
        .WIDTH(WIDTH)
    ) u_output_driver (
        .in_value     (counter_value),
        .out_value    (wave_out)
    );
    
endmodule

// 子模块1 - 可配置步进计数器
module ramp_counter #(
    parameter WIDTH = 8,
    parameter STEP  = 2
)(
    input  wire             clk,
    input  wire             rst,
    output reg  [WIDTH-1:0] counter_out
);
    // 使用条件运算符替代if-else结构
    always @(posedge clk) begin
        counter_out <= rst ? {WIDTH{1'b0}} : counter_out + STEP;
    end
endmodule

// 子模块2 - 输出驱动
module output_driver #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] in_value,
    output wire [WIDTH-1:0] out_value
);
    // 直接连接，可在此添加额外输出处理逻辑
    assign out_value = in_value;
endmodule