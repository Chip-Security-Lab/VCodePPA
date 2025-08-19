//SystemVerilog
module combo_logic_xnor (
    input  wire clk,       // 时钟信号
    input  wire rst_n,     // 异步复位，低电平有效
    input  wire in_data1,  // 输入数据1
    input  wire in_data2,  // 输入数据2
    output reg  out_data   // 输出数据
);

    // 内部信号声明 - 数据路径分割为两个阶段
    reg stage1_in_data1_reg;
    reg stage1_in_data2_reg;
    wire stage1_xnor_result;

    // 第一阶段 - 注册输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_in_data1_reg <= 1'b0;
            stage1_in_data2_reg <= 1'b0;
        end else begin
            stage1_in_data1_reg <= in_data1;
            stage1_in_data2_reg <= in_data2;
        end
    end

    // 组合逻辑计算 - XNOR操作
    assign stage1_xnor_result = ~(stage1_in_data1_reg ^ stage1_in_data2_reg);

    // 第二阶段 - 注册输出结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data <= 1'b0;
        end else begin
            out_data <= stage1_xnor_result;
        end
    end

endmodule