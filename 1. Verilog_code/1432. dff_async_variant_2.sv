//SystemVerilog
module dff_async (
    input  wire clk,     // 时钟信号
    input  wire arst_n,  // 异步复位信号，低电平有效
    input  wire d,       // 数据输入
    output reg  q        // 数据输出
);

    // 增加中间流水线级寄存器
    reg stage1_data;
    reg stage2_data;
    reg stage3_data;
    
    // 第一级流水线 - 输入捕获
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            stage1_data <= 1'b0;   // 异步复位时将寄存器置零
        else
            stage1_data <= d;      // 捕获输入数据
    end
    
    // 第二级流水线 - 数据处理阶段1
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            stage2_data <= 1'b0;
        else
            stage2_data <= stage1_data;
    end
    
    // 第三级流水线 - 数据处理阶段2
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            stage3_data <= 1'b0;
        else
            stage3_data <= stage2_data;
    end
    
    // 第四级流水线 - 输出阶段
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            q <= 1'b0;
        else
            q <= stage3_data;
    end

endmodule