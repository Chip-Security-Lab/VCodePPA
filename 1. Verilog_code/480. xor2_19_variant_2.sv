//SystemVerilog
//IEEE 1364-2005 Verilog标准
module xor2_19 (
    input  wire clk,    // 时钟输入用于寄存器时序控制
    input  wire rst_n,  // 复位信号
    input  wire A, B,   // 输入信号
    output wire Y       // 输出信号
);
    // 将流水线深度从3级增加到5级
    
    // 阶段1: 捕获输入A
    reg stage1_a;
    
    // 阶段2: 捕获输入B
    reg stage2_a, stage2_b;
    
    // 阶段3: 预处理输入信号
    reg stage3_a, stage3_b;
    
    // 阶段4: 执行XOR运算
    reg stage4_result;
    
    // 阶段5: 输出缓冲寄存器
    reg stage5_result;
    
    // 阶段1: 输入A寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 1'b0;
        end else begin
            stage1_a <= A;
        end
    end
    
    // 阶段2: 输入B和传递A
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_a <= 1'b0;
            stage2_b <= 1'b0;
        end else begin
            stage2_a <= stage1_a;
            stage2_b <= B;
        end
    end
    
    // 阶段3: 预处理信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_a <= 1'b0;
            stage3_b <= 1'b0;
        end else begin
            stage3_a <= stage2_a;
            stage3_b <= stage2_b;
        end
    end
    
    // 阶段4: XOR计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage4_result <= 1'b0;
        end else begin
            stage4_result <= stage3_a ^ stage3_b;
        end
    end
    
    // 阶段5: 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage5_result <= 1'b0;
        end else begin
            stage5_result <= stage4_result;
        end
    end
    
    // 将最终寄存器输出连接到模块输出
    assign Y = stage5_result;
    
endmodule