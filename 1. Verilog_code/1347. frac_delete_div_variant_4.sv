//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// 顶层模块：分数频率分频器
///////////////////////////////////////////////////////////////////////////////
module frac_delete_div #(
    parameter ACC_WIDTH = 8
)(
    input  wire clk,
    input  wire rst,
    output wire clk_out
);

    // 内部连线
    wire [ACC_WIDTH-1:0] accumulator_value;
    wire                 compare_result;

    // 实例化累加器子模块
    accumulator_module #(
        .WIDTH(ACC_WIDTH)
    ) acc_inst (
        .clk              (clk),
        .rst              (rst),
        .increment_value  (3),  // 增量为3，产生(3/8)*2=0.75的分频比
        .accumulator_out  (accumulator_value)
    );

    // 实例化比较器子模块
    comparator_module #(
        .WIDTH(ACC_WIDTH)
    ) comp_inst (
        .value_in         (accumulator_value),
        .threshold        (8'h80),
        .compare_out      (compare_result)
    );

    // 实例化输出处理子模块
    output_handler out_inst (
        .clk              (clk),
        .rst              (rst),
        .compare_result   (compare_result),
        .clk_out          (clk_out)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// 累加器子模块：负责累加计数
///////////////////////////////////////////////////////////////////////////////
module accumulator_module #(
    parameter WIDTH = 8
)(
    input  wire              clk,
    input  wire              rst,
    input  wire [WIDTH-1:0]  increment_value,
    output reg  [WIDTH-1:0]  accumulator_out
);

    always @(posedge clk) begin
        if (rst) begin
            accumulator_out <= {WIDTH{1'b0}};
        end else begin
            accumulator_out <= accumulator_out + increment_value;
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// 比较器子模块：比较累加值与阈值
///////////////////////////////////////////////////////////////////////////////
module comparator_module #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0]  value_in,
    input  wire [WIDTH-1:0]  threshold,
    output reg               compare_out
);

    // 比较逻辑：当value_in小于threshold时，输出1
    always @(*) begin
        if (value_in < threshold) begin
            compare_out = 1'b1;
        end else begin
            compare_out = 1'b0;
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// 输出处理子模块：生成最终时钟输出
///////////////////////////////////////////////////////////////////////////////
module output_handler (
    input  wire clk,
    input  wire rst,
    input  wire compare_result,
    output reg  clk_out
);

    always @(posedge clk) begin
        if (rst) begin
            clk_out <= 1'b0;
        end else begin
            clk_out <= compare_result;
        end
    end

endmodule