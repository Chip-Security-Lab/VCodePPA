//SystemVerilog
module and_or_gate_4input (
    input  wire clk,         // 时钟信号(新增)
    input  wire rst_n,       // 复位信号(新增)
    input  wire A, B, C, D,  // 四个输入
    output wire Y            // 输出Y
);
    // 分段流水线寄存器
    reg  stage1_A, stage1_B, stage1_C;
    wire stage1_AB;
    reg  stage2_AB, stage2_CD;
    
    // 第一级流水线 - 输入缓存和第一个与操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A <= 1'b0;
            stage1_B <= 1'b0;
            stage1_C <= 1'b0;
        end else begin
            stage1_A <= A;
            stage1_B <= B;
            stage1_C <= C;
        end
    end
    
    // 第一级组合逻辑 - AB与操作
    assign stage1_AB = stage1_A & stage1_B;
    
    // 第二级流水线 - 中间结果寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_AB <= 1'b0;
            stage2_CD <= 1'b0;
        end else begin
            stage2_AB <= stage1_AB;
            stage2_CD <= stage1_C & B; // CD与操作
        end
    end
    
    // 最终组合逻辑 - 或操作输出
    assign Y = stage2_AB | stage2_CD;
    
endmodule