//SystemVerilog
//IEEE 1364-2005 Verilog
module xor_task_based(
    input  wire clk,     // 时钟信号
    input  wire rst_n,   // 低电平有效复位
    input  wire a,       // 输入A
    input  wire b,       // 输入B
    output wire y        // 输出Y
);
    // 数据流阶段定义
    // 阶段1: 输入寄存
    reg a_stage1, b_stage1;
    
    // 阶段2: XOR计算和寄存
    wire xor_result_stage2;
    reg  xor_result_stage3;
    
    // 阶段1：输入捕获寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
        end
    end
    
    // 阶段2：组合逻辑计算
    assign xor_result_stage2 = a_stage1 ^ b_stage1;
    
    // 阶段3：输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_result_stage3 <= 1'b0;
        end else begin
            xor_result_stage3 <= xor_result_stage2;
        end
    end
    
    // 输出赋值
    assign y = xor_result_stage3;
    
endmodule