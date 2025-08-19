//SystemVerilog
module redun_logic_xnor (
    input  wire clk,   // 添加时钟信号以支持流水线结构
    input  wire rst_n, // 添加复位信号
    input  wire a, 
    input  wire b, 
    input  wire c, 
    input  wire d,
    output wire y
);

    // 第一级流水线：处理输入对比
    reg stage1_a_eq_b;
    reg stage1_c_eq_d;
    
    // 第二级流水线：最终输出结果
    reg stage2_result;
    
    // 阶段1：计算相等比较，切分数据路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a_eq_b <= 1'b0;
            stage1_c_eq_d <= 1'b0;
        end else begin
            stage1_a_eq_b <= (a == b); // 第一组输入的XNOR等价
            stage1_c_eq_d <= (c == d); // 第二组输入的XNOR等价
        end
    end
    
    // 阶段2：比较两个XNOR结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 1'b0;
        end else begin
            stage2_result <= (stage1_a_eq_b == stage1_c_eq_d);
        end
    end
    
    // 输出赋值
    assign y = stage2_result;

endmodule