//SystemVerilog
// 顶层模块
module threshold_reset_gen(
    input  wire       clk,
    input  wire [7:0] signal_value,
    input  wire [7:0] threshold,
    output wire       reset_out
);
    // 连接信号
    wire compare_result;
    
    // 比较器子模块实例化
    comparator_module comparator_inst (
        .clk           (clk),
        .signal_value  (signal_value),
        .threshold     (threshold),
        .result        (compare_result)
    );
    
    // 输出寄存器子模块实例化
    output_register_module output_reg_inst (
        .clk           (clk),
        .compare_in    (compare_result),
        .reset_out     (reset_out)
    );
    
endmodule

// 比较器子模块 - 负责信号阈值比较逻辑
module comparator_module(
    input  wire       clk,
    input  wire [7:0] signal_value,
    input  wire [7:0] threshold,
    output reg        result
);
    // 比较逻辑
    always @(posedge clk) begin
        result <= (signal_value > threshold);
    end
endmodule

// 输出寄存器子模块 - 负责管理复位输出信号
module output_register_module(
    input  wire clk,
    input  wire compare_in,
    output reg  reset_out
);
    // 输出寄存器逻辑
    always @(posedge clk) begin
        reset_out <= compare_in ? 1'b1 : 1'b0;
    end
endmodule