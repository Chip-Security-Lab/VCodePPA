//SystemVerilog
module lfsr_ring_counter (
    input wire clk,
    input wire rst_n,        // 添加复位信号
    input wire enable,
    input wire data_valid_in, // 输入数据有效信号
    output wire data_valid_out, // 输出数据有效信号
    output wire [3:0] lfsr_out  // 输出结果
);
    // 流水线寄存器
    reg [3:0] lfsr_stage1;
    reg [3:0] lfsr_stage2;
    reg [3:0] lfsr_stage3;
    
    // 流水线控制信号
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    // 反馈逻辑 - 第一级流水线
    wire feedback_stage1 = lfsr_stage1[0];
    wire [3:0] next_lfsr_stage1 = enable ? {feedback_stage1, lfsr_stage1[3:1]} : 4'b0001;
    
    // 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_stage1 <= 4'b0001;
            valid_stage1 <= 1'b0;
        end else begin
            lfsr_stage1 <= data_valid_in ? next_lfsr_stage1 : lfsr_stage1;
            valid_stage1 <= data_valid_in;
        end
    end
    
    // 第二级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end else begin
            lfsr_stage2 <= valid_stage1 ? lfsr_stage1 : lfsr_stage2;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_stage3 <= 4'b0000;
            valid_stage3 <= 1'b0;
        end else begin
            lfsr_stage3 <= valid_stage2 ? lfsr_stage2 : lfsr_stage3;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出赋值
    assign lfsr_out = lfsr_stage3;
    assign data_valid_out = valid_stage3;
    
endmodule