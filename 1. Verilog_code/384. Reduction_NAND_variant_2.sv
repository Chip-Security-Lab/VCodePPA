//SystemVerilog
// 顶层模块 - 流水线化的NAND归约
module Reduction_NAND (
    input wire clk,          // 新增时钟信号，用于流水线寄存器
    input wire rst_n,        // 新增复位信号，用于初始化流水线寄存器
    input wire [7:0] vec,    // 输入向量
    output wire result       // 归约NAND结果
);
    // 内部流水线信号定义
    wire [3:0] stage1_partial_and;    // 第一级流水线部分与结果
    reg [3:0] stage1_reg;             // 第一级流水线寄存器
    wire stage2_and_result;           // 第二级流水线与结果
    reg stage2_reg;                   // 第二级流水线寄存器
    wire stage3_nand_result;          // 最终NAND结果

    // 第一级流水线：8位向量分成两部分，先计算4位一组的与结果
    Stage1_Partial_AND stage1_inst (
        .data(vec),
        .partial_results(stage1_partial_and)
    );
    
    // 第一级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage1_reg <= 4'b1111;  // 复位值确保不影响与操作
        else
            stage1_reg <= stage1_partial_and;
    end
    
    // 第二级流水线：合并第一级的结果
    Stage2_Final_AND stage2_inst (
        .partial_data(stage1_reg),
        .and_result(stage2_and_result)
    );
    
    // 第二级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage2_reg <= 1'b1;  // 复位值确保不影响与操作
        else
            stage2_reg <= stage2_and_result;
    end
    
    // 第三级流水线：最终求反操作
    Stage3_Inverter stage3_inst (
        .data_in(stage2_reg),
        .nand_result(stage3_nand_result)
    );
    
    // 输出结果
    assign result = stage3_nand_result;
endmodule

// 第一级流水线模块：4位分组部分与运算
module Stage1_Partial_AND (
    input wire [7:0] data,
    output wire [3:0] partial_results
);
    // 将8位数据分成4组，每组2位计算部分与
    assign partial_results[0] = data[0] & data[1];
    assign partial_results[1] = data[2] & data[3];
    assign partial_results[2] = data[4] & data[5];
    assign partial_results[3] = data[6] & data[7];
endmodule

// 第二级流水线模块：合并第一级的结果完成最终与运算
module Stage2_Final_AND (
    input wire [3:0] partial_data,
    output wire and_result
);
    // 两级树形结构完成最终与操作
    wire [1:0] intermediate;
    
    assign intermediate[0] = partial_data[0] & partial_data[1];
    assign intermediate[1] = partial_data[2] & partial_data[3];
    assign and_result = intermediate[0] & intermediate[1];
endmodule

// 第三级流水线模块：完成反相操作
module Stage3_Inverter (
    input wire data_in,
    output wire nand_result
);
    // 对与结果取反得到NAND结果
    assign nand_result = ~data_in;
endmodule