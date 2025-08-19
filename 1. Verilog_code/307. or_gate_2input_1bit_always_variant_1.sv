//SystemVerilog
module or_gate_2input_1bit_always (
    input  wire clk,       // 时钟信号
    input  wire rst_n,     // 低电平有效复位信号
    input  wire a,         // 输入信号a
    input  wire b,         // 输入信号b
    output reg  y_out      // 最终输出结果
);
    // 数据流水线寄存器定义
    // 阶段1: 输入捕获
    reg a_stage1, b_stage1;
    
    // 阶段2: 运算结果
    reg result_stage2;
    
    // 阶段1: 输入数据捕获
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位所有阶段1寄存器
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
        end 
        else begin
            // 捕获输入数据
            a_stage1 <= a;
            b_stage1 <= b;
        end
    end
    
    // 阶段2: 执行逻辑运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位阶段2寄存器
            result_stage2 <= 1'b0;
        end 
        else begin
            // 执行OR运算并存储
            result_stage2 <= a_stage1 | b_stage1;
        end
    end
    
    // 阶段3: 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位输出寄存器
            y_out <= 1'b0;
        end 
        else begin
            // 将结果传递到输出
            y_out <= result_stage2;
        end
    end
endmodule