//SystemVerilog
module pipeline_sync_rst #(parameter WIDTH=8, parameter COMPUTE_STAGES=3)(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [WIDTH-1:0] din,
    output wire valid_out,
    output reg [WIDTH-1:0] dout,
    input wire ready_in,
    output wire ready_out
);

    // 增加流水线深度 - 将原来的3级流水线扩展为5级
    // 流水线数据寄存器
    reg [WIDTH-1:0] stage1_data, stage2_data, stage3_data, stage4_data, stage5_data;
    
    // 流水线有效信号
    reg stage1_valid, stage2_valid, stage3_valid, stage4_valid, stage5_valid;
    
    // 流水线就绪信号（向后传播）
    wire stage5_ready, stage4_ready, stage3_ready, stage2_ready, stage1_ready;
    
    // 增加计算单元寄存器
    reg [WIDTH-1:0] compute_stage1, compute_stage2, compute_stage3;
    
    // 就绪信号传播（向后传播）
    assign stage5_ready = ready_in;
    assign stage4_ready = !stage5_valid || stage5_ready;
    assign stage3_ready = !stage4_valid || stage4_ready;
    assign stage2_ready = !stage3_valid || stage3_ready;
    assign stage1_ready = !stage2_valid || stage2_ready;
    assign ready_out = !stage1_valid || stage1_ready;
    
    // 输出赋值
    assign valid_out = stage5_valid;
    
    // 阶段1：输入阶段
    always @(posedge clk) begin
        if (rst) begin
            stage1_data <= 0;
            stage1_valid <= 0;
        end else begin
            if (ready_out && valid_in) begin
                stage1_data <= din;
                stage1_valid <= 1'b1;
            end else if (stage1_ready) begin
                stage1_valid <= 1'b0;
            end
        end
    end
    
    // 阶段2：第一计算阶段
    always @(posedge clk) begin
        if (rst) begin
            stage2_data <= 0;
            stage2_valid <= 0;
            compute_stage1 <= 0;
        end else begin
            if (stage1_ready && stage1_valid) begin
                // 在此处添加计算逻辑
                compute_stage1 <= stage1_data + (stage1_data << 1); // 示例计算
                stage2_data <= stage1_data;
                stage2_valid <= stage1_valid;
            end else if (stage2_ready) begin
                stage2_valid <= 1'b0;
            end
        end
    end
    
    // 阶段3：第二计算阶段
    always @(posedge clk) begin
        if (rst) begin
            stage3_data <= 0;
            stage3_valid <= 0;
            compute_stage2 <= 0;
        end else begin
            if (stage2_ready && stage2_valid) begin
                // 在此处添加计算逻辑
                compute_stage2 <= compute_stage1 ^ stage2_data; // 示例计算
                stage3_data <= compute_stage1;
                stage3_valid <= stage2_valid;
            end else if (stage3_ready) begin
                stage3_valid <= 1'b0;
            end
        end
    end
    
    // 阶段4：第三计算阶段
    always @(posedge clk) begin
        if (rst) begin
            stage4_data <= 0;
            stage4_valid <= 0;
            compute_stage3 <= 0;
        end else begin
            if (stage3_ready && stage3_valid) begin
                // 在此处添加计算逻辑
                compute_stage3 <= compute_stage2 | stage3_data; // 示例计算
                stage4_data <= compute_stage2;
                stage4_valid <= stage3_valid;
            end else if (stage4_ready) begin
                stage4_valid <= 1'b0;
            end
        end
    end
    
    // 阶段5：输出阶段
    always @(posedge clk) begin
        if (rst) begin
            stage5_data <= 0;
            stage5_valid <= 0;
        end else begin
            if (stage4_ready && stage4_valid) begin
                stage5_data <= compute_stage3;
                stage5_valid <= stage4_valid;
            end else if (stage5_ready) begin
                stage5_valid <= 1'b0;
            end
        end
    end
    
    // 输出赋值
    always @(posedge clk) begin
        if (rst) begin
            dout <= 0;
        end else if (stage5_valid && stage5_ready) begin
            dout <= stage5_data;
        end
    end
    
    // 性能计数器（可选）
    reg [31:0] throughput_counter;
    
    always @(posedge clk) begin
        if (rst) begin
            throughput_counter <= 0;
        end else if (valid_out && ready_in) begin
            throughput_counter <= throughput_counter + 1;
        end
    end
    
endmodule