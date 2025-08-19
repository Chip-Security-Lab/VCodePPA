//SystemVerilog
module sync_rst_buffer (
    input wire clk,
    input wire rst,
    input wire [31:0] data_in,
    input wire load,
    output wire [31:0] data_out,
    // 增加流水线控制接口
    output wire pipeline_ready,
    input wire next_stage_ready,
    output wire data_valid
);
    // 流水线阶段1寄存器
    reg [31:0] stage1_data;
    reg stage1_valid;
    
    // 流水线阶段2寄存器
    reg [31:0] stage2_data;
    reg stage2_valid;
    
    // 流水线阶段3寄存器 (输出阶段)
    reg [31:0] stage3_data;
    reg stage3_valid;
    
    // 流水线就绪信号
    reg [2:0] stage_ready;

    // 数据处理逻辑 - 各阶段加入处理功能
    wire [31:0] stage1_processed_data;
    wire [31:0] stage2_processed_data;
    
    // 阶段1数据处理 - 示例为简单的位操作
    assign stage1_processed_data = {stage1_data[15:0], stage1_data[31:16]};
    
    // 阶段2数据处理 - 示例为简单的算术运算
    assign stage2_processed_data = stage2_data + 32'h1;
    
    // 流水线控制逻辑
    always @(*) begin
        stage_ready[2] = next_stage_ready | ~stage3_valid;
        stage_ready[1] = stage_ready[2] | ~stage2_valid;
        stage_ready[0] = stage_ready[1] | ~stage1_valid;
    end
    
    // 输出就绪信号
    assign pipeline_ready = stage_ready[0];
    
    // 输出有效信号
    assign data_valid = stage3_valid;
    
    // 阶段1: 输入捕获和初步处理
    always @(posedge clk) begin
        if (rst) begin
            stage1_data <= 32'b0;
            stage1_valid <= 1'b0;
        end else if (pipeline_ready) begin
            if (load) begin
                stage1_data <= data_in;
                stage1_valid <= 1'b1;
            end else if (stage_ready[1]) begin
                stage1_valid <= 1'b0;
            end
        end
    end
    
    // 阶段2: 中间处理
    always @(posedge clk) begin
        if (rst) begin
            stage2_data <= 32'b0;
            stage2_valid <= 1'b0;
        end else if (stage_ready[1]) begin
            if (stage1_valid) begin
                stage2_data <= stage1_processed_data;
                stage2_valid <= 1'b1;
            end else if (stage_ready[2]) begin
                stage2_valid <= 1'b0;
            end
        end
    end
    
    // 阶段3: 输出阶段
    always @(posedge clk) begin
        if (rst) begin
            stage3_data <= 32'b0;
            stage3_valid <= 1'b0;
        end else if (stage_ready[2]) begin
            if (stage2_valid) begin
                stage3_data <= stage2_processed_data;
                stage3_valid <= 1'b1;
            end else if (next_stage_ready) begin
                stage3_valid <= 1'b0;
            end
        end
    end
    
    // 输出赋值
    assign data_out = stage3_data;
    
endmodule