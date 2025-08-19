//SystemVerilog
module Comparator_DualEdge #(parameter WIDTH = 8) (
    input              clk,
    input              rst_n,
    input              valid_in,
    input  [WIDTH-1:0] x, y,
    output reg         neq,
    output reg         valid_out
);
    // 流水线阶段1: 数据寄存与初步比较
    reg [WIDTH-1:0] x_stage1, y_stage1;
    reg valid_stage1;
    reg [WIDTH-1:0] diff_stage1;
    reg [WIDTH:0] borrow; // 借位信号
    
    // 流水线阶段2: 检查差异并产生最终结果
    reg valid_stage2;
    reg has_diff_stage2;
    
    // 借位减法器逻辑
    wire [WIDTH:0] borrow_wire;
    wire [WIDTH-1:0] diff_wire;
    
    assign borrow_wire[0] = 1'b0; // 初始无借位
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: borrow_subtractor
            assign diff_wire[i] = x[i] ^ y[i] ^ borrow_wire[i];
            assign borrow_wire[i+1] = (~x[i] & y[i]) | (~x[i] & borrow_wire[i]) | (y[i] & borrow_wire[i]);
        end
    endgenerate
    
    // 流水线第一级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_stage1 <= 0;
            y_stage1 <= 0;
            valid_stage1 <= 1'b0;
            diff_stage1 <= 0;
            borrow <= 0;
        end else begin
            x_stage1 <= x;
            y_stage1 <= y;
            valid_stage1 <= valid_in;
            diff_stage1 <= diff_wire; // 使用借位减法器计算差异
            borrow <= borrow_wire;
        end
    end
    
    // 流水线第二级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            has_diff_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            // 如果借位输出非零或任何位差异非零，则表示不相等
            has_diff_stage2 <= (|diff_stage1) | borrow[WIDTH];
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 流水线第三级 - 输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            neq <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            neq <= has_diff_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule