//SystemVerilog
// 顶层模块 - 流水线架构
module xor2_16 (
    input wire A, B,
    input wire clk, rst_n,  // 添加复位信号
    input wire valid_in,    // 输入有效信号
    output wire valid_out,  // 输出有效信号
    output wire Y,
    output wire ready       // 流水线就绪信号
);
    // 流水线阶段信号
    wire stage1_valid, stage2_valid;
    wire stage1_xor_result;
    
    // 实例化流水线子模块
    xor_pipeline_stage1 stage1 (
        .clk(clk),
        .rst_n(rst_n),
        .A(A),
        .B(B),
        .valid_in(valid_in),
        .valid_out(stage1_valid),
        .xor_result(stage1_xor_result),
        .ready(ready)
    );
    
    xor_pipeline_stage2 stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(stage1_valid),
        .xor_result_in(stage1_xor_result),
        .valid_out(valid_out),
        .Y(Y)
    );
endmodule

// 第一级流水线 - 执行异或逻辑
module xor_pipeline_stage1 (
    input wire clk, rst_n,
    input wire A, B,
    input wire valid_in,
    output reg valid_out,
    output reg xor_result,
    output wire ready
);
    // 流水线控制逻辑
    assign ready = 1'b1;  // 本例中流水线始终就绪
    
    // 流水线第一级寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            xor_result <= 1'b0;
        end else begin
            valid_out <= valid_in;
            if (valid_in) begin
                xor_result <= A ^ B;  // 执行异或运算并寄存结果
            end
        end
    end
endmodule

// 第二级流水线 - 输出寄存器逻辑
module xor_pipeline_stage2 (
    input wire clk, rst_n,
    input wire valid_in,
    input wire xor_result_in,
    output reg valid_out,
    output reg Y
);
    // 流水线第二级寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            Y <= 1'b0;
        end else begin
            valid_out <= valid_in;
            if (valid_in) begin
                Y <= xor_result_in;  // 输出最终结果
            end
        end
    end
endmodule