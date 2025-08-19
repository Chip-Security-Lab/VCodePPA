//SystemVerilog - IEEE 1364-2005
module adaptive_threshold_recovery (
    input wire clk,
    input wire reset,
    // 输入接口 - Valid-Ready握手
    input wire input_valid,
    output wire input_ready,
    input wire [7:0] signal_in,
    input wire [7:0] noise_level,
    // 输出接口 - Valid-Ready握手
    output reg output_valid,
    input wire output_ready,
    output reg [7:0] signal_out
);
    // 流水线阶段控制信号
    reg valid_stage1, valid_stage2;
    wire ready_stage1, ready_stage2;
    
    // 阶段1：数据采样和阈值计算
    reg [7:0] signal_stage1;
    reg [7:0] threshold_stage1;
    
    // 阶段2：信号处理和比较
    reg [7:0] signal_stage2;
    reg [7:0] threshold_stage2;
    
    // 流水线反压逻辑
    assign ready_stage2 = ~output_valid | output_ready;
    assign ready_stage1 = ~valid_stage2 | ready_stage2;
    assign input_ready = ~valid_stage1 | ready_stage1;
    
    // 阶段1：数据采样和阈值计算
    always @(posedge clk) begin
        if (reset) begin
            valid_stage1 <= 1'b0;
            signal_stage1 <= 8'd0;
            threshold_stage1 <= 8'd128;
        end else if (input_valid && input_ready) begin
            valid_stage1 <= 1'b1;
            signal_stage1 <= signal_in;
            threshold_stage1 <= 8'd64 + (noise_level >> 1);
        end else if (ready_stage1) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 阶段2：将阶段1的数据传递到阶段2
    always @(posedge clk) begin
        if (reset) begin
            valid_stage2 <= 1'b0;
            signal_stage2 <= 8'd0;
            threshold_stage2 <= 8'd0;
        end else if (valid_stage1 && ready_stage1) begin
            valid_stage2 <= 1'b1;
            signal_stage2 <= signal_stage1;
            threshold_stage2 <= threshold_stage1;
        end else if (ready_stage2) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 输出阶段：应用阈值并生成输出信号
    always @(posedge clk) begin
        if (reset) begin
            output_valid <= 1'b0;
            signal_out <= 8'd0;
        end else if (valid_stage2 && ready_stage2) begin
            output_valid <= 1'b1;
            signal_out <= (signal_stage2 > threshold_stage2) ? signal_stage2 : 8'd0;
        end else if (output_ready) begin
            output_valid <= 1'b0;
        end
    end
endmodule