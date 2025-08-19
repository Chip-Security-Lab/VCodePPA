//SystemVerilog
module AsyncResetOR(
    input         clk,        // 添加时钟信号用于流水线寄存器
    input         rst_n,
    input  [3:0]  d1, d2,
    output [3:0]  q
);
    // 定义流水线寄存器信号
    reg  [3:0] d1_reg, d2_reg;      // 输入寄存器级
    wire [3:0] or_stage1;           // 组合逻辑结果
    reg  [3:0] or_result_reg;       // 逻辑操作结果寄存器
    wire [3:0] reset_data;          // 复位处理后数据
    
    // 阶段1: 输入寄存器层 - 捕获输入并同步
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d1_reg <= 4'b0000;
            d2_reg <= 4'b0000;
        end else begin
            d1_reg <= d1;
            d2_reg <= d2;
        end
    end
    
    // 阶段2: 逻辑运算层 - 实现OR逻辑，并添加流水线寄存器
    // 组合逻辑计算OR结果
    LogicOperation #(
        .WIDTH(4)
    ) logic_op_inst (
        .a(d1_reg),
        .b(d2_reg),
        .result(or_stage1)
    );
    
    // 逻辑结果寄存器级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            or_result_reg <= 4'b0000;
        end else begin
            or_result_reg <= or_stage1;
        end
    end
    
    // 阶段3: 复位处理层 - 处理异步复位
    ResetHandler #(
        .WIDTH(4),
        .RESET_VALUE(4'b1111)
    ) reset_handler_inst (
        .rst_n(rst_n),
        .data_in(or_result_reg),
        .data_out(reset_data)
    );
    
    // 输出赋值 - 可根据需要再增加一级输出寄存器
    assign q = reset_data;
endmodule

module LogicOperation #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] result
);
    // 分割组合逻辑深度，提高性能
    wire [WIDTH-1:0] partial_result;
    
    // 第一部分OR操作 - 可以添加更多的逻辑分割
    assign partial_result = a | b;
    
    // 最终OR结果
    assign result = partial_result;
endmodule

module ResetHandler #(
    parameter WIDTH = 4,
    parameter RESET_VALUE = {WIDTH{1'b1}}
)(
    input           rst_n,
    input  [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    // 复位处理逻辑，保持原有功能
    assign data_out = rst_n ? data_in : RESET_VALUE;
endmodule