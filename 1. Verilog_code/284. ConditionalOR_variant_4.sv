//SystemVerilog
// 顶层模块
module ConditionalOR(
    input logic clk,          // 添加时钟信号
    input logic resetn,       // 添加复位信号
    input logic cond,
    input logic [7:0] mask, data,
    output logic [7:0] result
);
    // 内部寄存器和数据流信号声明
    logic [7:0] data_reg, mask_reg, cond_reg;
    logic [7:0] masked_data_stage1;
    logic [7:0] result_internal;
    logic cond_stage1;
    
    // 输入寄存器级 - 分割输入路径
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            data_reg <= 8'h0;
            mask_reg <= 8'h0;
            cond_reg <= 1'b0;
        end else begin
            data_reg <= data;
            mask_reg <= mask;
            cond_reg <= cond;
        end
    end
    
    // 子模块实例化 - 掩码操作阶段
    MaskOperator mask_op (
        .clk(clk),
        .resetn(resetn),
        .data_in(data_reg),
        .mask(mask_reg),
        .data_out(masked_data_stage1),
        .cond_in(cond_reg),
        .cond_out(cond_stage1)
    );
    
    // 子模块实例化 - 数据选择阶段
    DataSelector data_selector (
        .clk(clk),
        .resetn(resetn),
        .cond(cond_stage1),
        .masked_data(masked_data_stage1),
        .original_data(data_reg),
        .result(result_internal)
    );
    
    // 输出寄存器级 - 分割输出路径
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            result <= 8'h0;
        end else begin
            result <= result_internal;
        end
    end
endmodule

// 子模块：执行OR操作 - 带流水线寄存器
module MaskOperator(
    input logic clk,
    input logic resetn,
    input logic [7:0] data_in,
    input logic [7:0] mask,
    output logic [7:0] data_out,
    input logic cond_in,
    output logic cond_out
);
    // 参数化设计，便于将来扩展到其他位宽和操作类型
    parameter OP_TYPE = "OR"; // 可以扩展为AND, XOR等
    
    // 内部信号用于计算结果
    logic [7:0] op_result;
    
    // 操作类型选择
    generate
        if (OP_TYPE == "OR") begin: gen_or_op
            assign op_result = data_in | mask;
        end
        // 可以扩展为其他类型的操作
        // else if (OP_TYPE == "AND") begin: gen_and_op
        //    assign op_result = data_in & mask;
        // end
    endgenerate
    
    // 流水线寄存器 - 将组合逻辑结果存储并传递到下一级
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            data_out <= 8'h0;
            cond_out <= 1'b0;
        end else begin
            data_out <= op_result;
            cond_out <= cond_in; // 传递控制信号到下一流水级
        end
    end
endmodule

// 子模块：基于条件选择数据 - 带流水线寄存器
module DataSelector(
    input logic clk,
    input logic resetn,
    input logic cond,
    input logic [7:0] masked_data,
    input logic [7:0] original_data,
    output logic [7:0] result
);
    // 内部信号用于计算结果
    logic [7:0] selected_data;
    
    // 使用三目运算符实现多路选择器
    assign selected_data = cond ? masked_data : original_data;
    
    // 流水线寄存器 - 存储选择结果
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            result <= 8'h0;
        end else begin
            result <= selected_data;
        end
    end
endmodule