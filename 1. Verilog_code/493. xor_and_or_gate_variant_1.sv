//SystemVerilog
//------------------------------------------------
// 顶层模块: 逻辑运算单元
//------------------------------------------------
module logic_processing_unit (
    input wire clk,           // 系统时钟
    input wire rst_n,         // 异步复位，低电平有效
    input wire [1:0] op_mode, // 操作模式选择
    input wire A, B, C,       // 输入信号
    output wire Y             // 输出结果
);
    // 内部连线
    wire stage1_result;       // 第一阶段计算结果
    wire stage2_result;       // 第二阶段计算结果
    
    // 实例化第一阶段处理单元 - 已优化
    input_processing_stage stage1 (
        .clk(clk),
        .rst_n(rst_n),
        .op_sel(op_mode[0]),
        .in1(A),
        .in2(B),
        .result(stage1_result)
    );
    
    // 实例化第二阶段处理单元 - 已优化
    secondary_processing_stage stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .op_sel(op_mode[1]),
        .in1(A),
        .in2(C),
        .result(stage2_result)
    );
    
    // 实例化输出合并单元 - 已优化
    output_combination_unit final_stage (
        .clk(clk),
        .rst_n(rst_n),
        .in1(stage1_result),
        .in2(stage2_result),
        .result(Y)
    );
endmodule

//------------------------------------------------
// 子模块: 第一阶段输入处理单元
//------------------------------------------------
module input_processing_stage (
    input wire clk,       // 系统时钟
    input wire rst_n,     // 异步复位
    input wire op_sel,    // 操作选择
    input wire in1, in2,  // 输入信号
    output reg result     // 处理结果
);
    // 直接在寄存器中计算结果，减少组合逻辑链路延迟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            result <= 1'b0;
        else
            result <= in1 ^ in2;  // XOR操作 - 条件选择逻辑冗余已移除
    end
endmodule

//------------------------------------------------
// 子模块: 第二阶段处理单元
//------------------------------------------------
module secondary_processing_stage (
    input wire clk,       // 系统时钟
    input wire rst_n,     // 异步复位
    input wire op_sel,    // 操作选择
    input wire in1, in2,  // 输入信号
    output reg result     // 处理结果
);
    // 预计算结果
    reg or_result;
    
    // 使用always块预计算，提高可综合性
    always @(*) begin
        or_result = in1 | in2;
    end
    
    // 使用单一寄存器，减少资源消耗
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            result <= 1'b0;
        else
            result <= op_sel ? or_result : in1;  // 条件选择优化
    end
endmodule

//------------------------------------------------
// 子模块: 输出合并单元
//------------------------------------------------
module output_combination_unit (
    input wire clk,       // 系统时钟
    input wire rst_n,     // 异步复位
    input wire in1, in2,  // 来自前级的处理结果
    output reg result     // 最终输出结果
);
    // 使用流水线方式计算，减少关键路径延迟
    reg stage1;
    
    // 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage1 <= 1'b0;
        else
            stage1 <= in1;
    end
    
    // 第二级流水线 - 最终结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            result <= 1'b0;
        else
            result <= stage1 & in2;  // 流水线化的AND操作
    end
endmodule