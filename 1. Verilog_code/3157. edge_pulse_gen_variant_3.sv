//SystemVerilog
module edge_pulse_gen(
    input clk,
    input reset,          // 添加复位信号
    input signal_in,
    input valid_in,       // 输入有效信号
    output reg pulse_out,
    output reg valid_out  // 输出有效信号
);
    // 流水线级1: 信号采样和延迟
    reg signal_stage1;
    reg signal_d_stage1;
    reg valid_stage1;
    
    // 流水线级2: 脉冲计算
    reg signal_stage2;
    reg signal_d_stage2;
    reg valid_stage2;
    
    // 流水线级1: 信号采样和延迟
    always @(posedge clk) begin
        if (reset) begin
            signal_stage1 <= 1'b0;
            signal_d_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            signal_stage1 <= signal_in;
            signal_d_stage1 <= signal_stage1;
            valid_stage1 <= valid_in;
        end
    end
    
    // 流水线级2: 计算脉冲
    always @(posedge clk) begin
        if (reset) begin
            signal_stage2 <= 1'b0;
            signal_d_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            signal_stage2 <= signal_stage1;
            signal_d_stage2 <= signal_d_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 流水线级3: 输出阶段
    always @(posedge clk) begin
        if (reset) begin
            pulse_out <= 1'b0;
            valid_out <= 1'b0;
        end
        else begin
            pulse_out <= signal_stage2 & ~signal_d_stage2;  // 上升沿检测
            valid_out <= valid_stage2;
        end
    end
endmodule