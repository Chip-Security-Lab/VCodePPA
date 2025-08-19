//SystemVerilog
module SyncOR_Top (
    input        clk,
    input  [7:0] data1,
    input  [7:0] data2,
    output [7:0] q
);
    wire [7:0] or_stage1;
    wire [7:0] or_stage2;

    // 逻辑子模块：8位位宽的按位或运算，增加一级流水线寄存器
    OrUnit_Pipelined #(.WIDTH(8)) or_unit_pipelined_inst (
        .clk   (clk),
        .a     (data1),
        .b     (data2),
        .y     (or_stage1)
    );

    // 多一级同步寄存器以保持数据路径时序一致
    SyncRegister #(.WIDTH(8)) sync_reg_stage2_inst (
        .clk   (clk),
        .d     (or_stage1),
        .q     (or_stage2)
    );

    // 最终输出同步寄存器
    SyncRegister #(.WIDTH(8)) sync_reg_out_inst (
        .clk   (clk),
        .d     (or_stage2),
        .q     (q)
    );
endmodule

// -----------------------------------------------------------------------------
// OrUnit_Pipelined: 8位或运算子模块（带一个流水线寄存器）
// 功能：对输入a和b执行按位或运算，增加一级寄存器减少组合路径长度
// -----------------------------------------------------------------------------
module OrUnit_Pipelined #(
    parameter WIDTH = 8
)(
    input              clk,
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output reg [WIDTH-1:0] y
);
    reg [WIDTH-1:0] or_comb_result;

    always @(*) begin
        or_comb_result = a | b;
    end

    always @(posedge clk) begin
        y <= or_comb_result;
    end
endmodule

// -----------------------------------------------------------------------------
// SyncRegister: 同步寄存器子模块
// 功能：在时钟上升沿将输入d寄存到输出q
// -----------------------------------------------------------------------------
module SyncRegister #(
    parameter WIDTH = 8
)(
    input              clk,
    input  [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk) begin
        q <= d;
    end
endmodule