//SystemVerilog
module reset_monitor(
    input wire clk,
    input wire [3:0] reset_inputs,
    output reg [3:0] reset_outputs,
    output reg [3:0] reset_status
);
    // 流水线阶段1寄存器
    reg [3:0] reset_inputs_stage1;
    reg valid_stage1;
    
    // 流水线阶段2寄存器
    reg [3:0] reset_processing_stage2a;
    reg [1:0] reset_processing_upper_stage2a;
    reg [1:0] reset_processing_lower_stage2a;
    reg valid_stage2a;
    
    // 流水线阶段2b寄存器
    reg [3:0] reset_processing_stage2b;
    reg valid_stage2b;
    
    // 流水线阶段3a寄存器
    reg [3:0] reset_processing_stage3a;
    reg valid_stage3a;
    
    // 流水线阶段3b寄存器
    reg [1:0] reset_outputs_upper_stage3b;
    reg [1:0] reset_outputs_lower_stage3b;
    reg valid_stage3b;
    
    // 阶段1: 捕获输入
    always @(posedge clk) begin
        reset_inputs_stage1 <= reset_inputs;
        valid_stage1 <= 1'b1; // 指示阶段1数据有效
    end
    
    // 阶段2a: 处理信号第一部分
    always @(posedge clk) begin
        if (valid_stage1) begin
            reset_processing_upper_stage2a <= reset_inputs_stage1[3:2];
            reset_processing_lower_stage2a <= reset_inputs_stage1[1:0];
            reset_processing_stage2a <= reset_inputs_stage1;
            valid_stage2a <= valid_stage1;
        end else begin
            valid_stage2a <= 1'b0;
        end
    end
    
    // 阶段2b: 处理信号第二部分
    always @(posedge clk) begin
        if (valid_stage2a) begin
            reset_processing_stage2b <= reset_processing_stage2a;
            valid_stage2b <= valid_stage2a;
        end else begin
            valid_stage2b <= 1'b0;
        end
    end
    
    // 阶段3a: 准备输出
    always @(posedge clk) begin
        if (valid_stage2b) begin
            reset_processing_stage3a <= reset_processing_stage2b;
            valid_stage3a <= valid_stage2b;
        end else begin
            valid_stage3a <= 1'b0;
        end
    end
    
    // 阶段3b: 生成输出
    always @(posedge clk) begin
        if (valid_stage3a) begin
            reset_outputs_upper_stage3b <= reset_processing_stage3a[3:2];
            reset_outputs_lower_stage3b <= reset_processing_stage3a[1:0];
            valid_stage3b <= valid_stage3a;
        end else begin
            valid_stage3b <= 1'b0;
        end
    end
    
    // 阶段4: 最终输出
    always @(posedge clk) begin
        if (valid_stage3b) begin
            reset_outputs <= {reset_outputs_upper_stage3b, reset_outputs_lower_stage3b};
            reset_status <= {reset_outputs_upper_stage3b, reset_outputs_lower_stage3b};
        end
    end
endmodule