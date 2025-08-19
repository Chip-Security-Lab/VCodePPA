//SystemVerilog
module and_xor_not_gate (
    input wire clk,        // 时钟输入
    input wire reset_n,    // 低电平有效复位
    input wire A, B, C,    // 输入A, B, C
    output reg Y           // 输出Y
);
    // 内部流水线寄存器
    reg stage1_and_result;
    reg stage1_a_not;
    reg stage1_c;
    reg stage2_xor_result;
    
    // 为高扇出信号clk添加时钟缓冲
    (* keep = "true" *) reg clk_buf1, clk_buf2, clk_buf3;
    
    // 时钟缓冲器，分散时钟负载
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            clk_buf1 <= 1'b0;
            clk_buf2 <= 1'b0;
            clk_buf3 <= 1'b0;
        end else begin
            clk_buf1 <= ~clk_buf1;
            clk_buf2 <= ~clk_buf2;
            clk_buf3 <= ~clk_buf3;
        end
    end
    
    // 缓存B信号，减少扇出负载
    reg B_buf1, B_buf2;
    
    // B值缓冲
    always @(posedge clk_buf1 or negedge reset_n) begin
        if (!reset_n) begin
            B_buf1 <= 1'b0;
            B_buf2 <= 1'b0;
        end else begin
            B_buf1 <= B;
            B_buf2 <= B;
        end
    end
    
    // 第一级流水线：计算A&B和~A，使用B的缓冲寄存器
    always @(posedge clk_buf1 or negedge reset_n) begin
        if (!reset_n) begin
            stage1_and_result <= 1'b0;
            stage1_a_not <= 1'b0;
            stage1_c <= 1'b0;
        end else begin
            stage1_and_result <= A & B_buf1;    // 与操作，使用缓冲的B信号
            stage1_a_not <= ~A;                // 非操作
            stage1_c <= C;                     // 传递C值
        end
    end
    
    // 第二级流水线：计算异或结果
    always @(posedge clk_buf2 or negedge reset_n) begin
        if (!reset_n) begin
            stage2_xor_result <= 1'b0;
        end else begin
            stage2_xor_result <= stage1_and_result ^ stage1_c;  // 异或操作
        end
    end
    
    // 复制stage1_a_not信号以减少扇出
    reg stage2_a_not;
    always @(posedge clk_buf2 or negedge reset_n) begin
        if (!reset_n) begin
            stage2_a_not <= 1'b0;
        end else begin
            stage2_a_not <= stage1_a_not;  // 传递非A的值到第二级
        end
    end
    
    // 第三级流水线：计算最终结果
    always @(posedge clk_buf3 or negedge reset_n) begin
        if (!reset_n) begin
            Y <= 1'b0;
        end else begin
            Y <= stage2_xor_result & stage2_a_not;  // 最终与操作，使用缓冲的非A信号
        end
    end
    
endmodule