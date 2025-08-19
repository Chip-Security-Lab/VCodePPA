//SystemVerilog
module error_diffusion (
    input wire clk,
    input wire [7:0] in,
    output reg [3:0] out
);
    // 内部信号声明 - 清晰标识数据流阶段
    reg [7:0] input_stage;          // 输入寄存器级
    reg [11:0] error_feedback;      // 误差反馈寄存器
    
    // 流水线第一级 - 数据路径分割
    reg [11:0] addition_result;     // 加法结果寄存器
    
    // 流水线第二级
    reg [11:0] quantization_error;  // 量化误差寄存器
    
    // 主数据流路径 - 分阶段处理
    always @(posedge clk) begin
        // 阶段1: 输入寄存和加法
        input_stage <= in;
        addition_result <= input_stage + error_feedback;
        
        // 阶段2: 输出量化
        out <= addition_result[11:8];
        
        // 阶段3: 误差计算和存储
        quantization_error <= (addition_result << 4) - ({out, 8'b0});
        error_feedback <= quantization_error;
    end
    
endmodule