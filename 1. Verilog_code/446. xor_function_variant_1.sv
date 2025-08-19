//SystemVerilog
module xor_function(
    input wire clk,       // 时钟输入
    input wire rst_n,     // 复位信号
    input wire a, b,      // 输入信号
    output reg y          // 输出
);
    // 内部信号定义，用于构建更深的流水线
    reg stage1_a, stage1_b;  // 第一级流水线寄存器
    reg stage2_a, stage2_b;  // 第二级流水线寄存器
    reg stage3_a, stage3_b;  // 第三级流水线寄存器
    reg stage4_result;       // 第四级流水线结果寄存器
    reg stage5_result;       // 第五级流水线结果寄存器
    
    // 功能函数定义 - 保持原始功能
    function automatic logic my_xor;
        input logic x, y;
        begin
            my_xor = x ^ y;  // 执行XOR操作
        end
    endfunction
    
    // 第一级流水线 - 输入缓存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 1'b0;
            stage1_b <= 1'b0;
        end else begin
            stage1_a <= a;
            stage1_b <= b;
        end
    end
    
    // 第二级流水线 - 信号传递阶段1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_a <= 1'b0;
            stage2_b <= 1'b0;
        end else begin
            stage2_a <= stage1_a;
            stage2_b <= stage1_b;
        end
    end
    
    // 第三级流水线 - 信号传递阶段2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_a <= 1'b0;
            stage3_b <= 1'b0;
        end else begin
            stage3_a <= stage2_a;
            stage3_b <= stage2_b;
        end
    end
    
    // 第四级流水线 - XOR计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage4_result <= 1'b0;
        end else begin
            stage4_result <= my_xor(stage3_a, stage3_b);
        end
    end
    
    // 第五级流水线 - 结果缓存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage5_result <= 1'b0;
        end else begin
            stage5_result <= stage4_result;
        end
    end
    
    // 第六级流水线 - 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
        end else begin
            y <= stage5_result;
        end
    end
    
endmodule