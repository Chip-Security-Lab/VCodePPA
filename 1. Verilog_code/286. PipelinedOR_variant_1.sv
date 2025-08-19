//SystemVerilog
// SystemVerilog
// 顶层模块，连接各个子模块
module PipelinedOR(
    input clk,
    input [15:0] stage_a, stage_b,
    output [15:0] out
);
    // 内部连线
    wire [7:0] stage1_lower_a, stage1_lower_b;
    wire [7:0] stage1_upper_a, stage1_upper_b;
    wire [7:0] stage2_lower_result;
    wire [7:0] stage2_upper_result;

    // 数据分割子模块实例
    DataSplitter u_splitter (
        .clk(clk),
        .data_a(stage_a),
        .data_b(stage_b),
        .lower_a(stage1_lower_a),
        .lower_b(stage1_lower_b),
        .upper_a(stage1_upper_a),
        .upper_b(stage1_upper_b)
    );

    // 逻辑运算子模块实例
    LogicProcessor u_processor (
        .clk(clk),
        .lower_a(stage1_lower_a),
        .lower_b(stage1_lower_b),
        .upper_a(stage1_upper_a),
        .upper_b(stage1_upper_b),
        .lower_result(stage2_lower_result),
        .upper_result(stage2_upper_result)
    );

    // 数据合并子模块实例
    DataMerger u_merger (
        .clk(clk),
        .lower_data(stage2_lower_result),
        .upper_data(stage2_upper_result),
        .out(out)
    );
endmodule

// 第一级流水线：数据分割子模块
module DataSplitter (
    input clk,
    input [15:0] data_a, data_b,
    output reg [7:0] lower_a, lower_b,
    output reg [7:0] upper_a, upper_b
);
    always @(posedge clk) begin
        lower_a <= data_a[7:0];
        lower_b <= data_b[7:0];
        upper_a <= data_a[15:8];
        upper_b <= data_b[15:8];
    end
endmodule

// 第二级流水线：逻辑运算子模块
module LogicProcessor #(
    parameter OP_WIDTH = 8
)(
    input clk,
    input [OP_WIDTH-1:0] lower_a, lower_b,
    input [OP_WIDTH-1:0] upper_a, upper_b,
    output reg [OP_WIDTH-1:0] lower_result,
    output reg [OP_WIDTH-1:0] upper_result
);
    always @(posedge clk) begin
        lower_result <= lower_a | lower_b;
        upper_result <= upper_a | upper_b;
    end
endmodule

// 第三级流水线：数据合并子模块
module DataMerger (
    input clk,
    input [7:0] lower_data, upper_data,
    output reg [15:0] out
);
    always @(posedge clk) begin
        out <= {upper_data, lower_data};
    end
endmodule