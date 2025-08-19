//SystemVerilog
//IEEE 1364-2005 Verilog
// 顶层模块 - 重组的数据流路径结构
module and_not_gate (
    input  wire clk,    // 时钟信号（添加以支持流水线）
    input  wire rst_n,  // 复位信号（添加以支持流水线）
    input  wire A, B,   // 输入A, B
    output wire Y       // 输出Y
);
    // 第一级流水线：计算基本门逻辑
    reg a_reg, b_reg;
    wire a_not_wire;    // A的非门输出
    wire a_b_and_wire;  // A与B的与门输出
    
    // 寄存输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 1'b0;
            b_reg <= 1'b0;
        end else begin
            a_reg <= A;
            b_reg <= B;
        end
    end
    
    // 并行计算基本逻辑门
    not_module stage1_not (
        .in(a_reg),
        .out(a_not_wire)
    );
    
    and_module stage1_and (
        .in_a(a_reg),
        .in_b(b_reg),
        .out(a_b_and_wire)
    );
    
    // 第二级流水线：寄存中间结果
    reg not_result_reg;
    reg and_result_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            not_result_reg <= 1'b0;
            and_result_reg <= 1'b0;
        end else begin
            not_result_reg <= a_not_wire;
            and_result_reg <= a_b_and_wire;
        end
    end
    
    // 第三级流水线：最终结果计算
    and_module stage3_final_and (
        .in_a(and_result_reg),
        .in_b(not_result_reg),
        .out(Y)
    );
    
endmodule

// 优化的与门模块
module and_module (
    input  wire in_a,
    input  wire in_b,
    output wire out
);
    // 参数化设计，便于未来扩展为多输入与门
    assign #1 out = in_a & in_b; // 添加小延迟以反映门延迟
endmodule

// 优化的非门模块
module not_module (
    input  wire in,
    output wire out
);
    assign #1 out = ~in; // 添加小延迟以反映门延迟
endmodule