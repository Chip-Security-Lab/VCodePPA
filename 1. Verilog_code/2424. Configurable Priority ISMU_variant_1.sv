//SystemVerilog
module config_priority_ismu #(parameter N_SRC = 8)(
    input wire clock, resetn,
    input wire [N_SRC-1:0] interrupt_in,
    input wire [N_SRC-1:0] interrupt_mask,
    input wire [3*N_SRC-1:0] priority_config,
    output reg [2:0] highest_priority,
    output reg interrupt_valid
);
    // 局部声明
    wire [2:0] priority_values [N_SRC-1:0];
    wire [N_SRC-1:0] valid_interrupts;
    reg [2:0] max_priority;
    reg [2:0] curr_max_id;
    
    // 优先级解码和有效中断预计算
    genvar g;
    generate
        for (g = 0; g < N_SRC; g = g + 1) begin : priority_decode
            assign priority_values[g] = priority_config[g*3+:3];
            assign valid_interrupts[g] = interrupt_in[g] & ~interrupt_mask[g];
        end
    endgenerate
    
    // 优化的中断优先级处理
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            interrupt_valid <= 1'b0;
            highest_priority <= 3'd0;
        end else begin
            // 重置信号
            interrupt_valid <= 1'b0;
            
            // 优化的优先级查找算法 - 使用预评估逻辑
            max_priority = 3'd0;
            curr_max_id = 3'd0;
            
            // 使用优先级级联比较而不是循环 - 先检查高优先级
            // 从最高可能优先级值开始检查
            // 优先级 7 (最高)
            if (valid_interrupts[7] && priority_values[7] > max_priority) begin
                max_priority = priority_values[7];
                curr_max_id = 3'd7;
            end
            
            if (valid_interrupts[6] && priority_values[6] > max_priority) begin
                max_priority = priority_values[6];
                curr_max_id = 3'd6;
            end
            
            if (valid_interrupts[5] && priority_values[5] > max_priority) begin
                max_priority = priority_values[5];
                curr_max_id = 3'd5;
            end
            
            if (valid_interrupts[4] && priority_values[4] > max_priority) begin
                max_priority = priority_values[4];
                curr_max_id = 3'd4;
            end
            
            if (valid_interrupts[3] && priority_values[3] > max_priority) begin
                max_priority = priority_values[3];
                curr_max_id = 3'd3;
            end
            
            if (valid_interrupts[2] && priority_values[2] > max_priority) begin
                max_priority = priority_values[2];
                curr_max_id = 3'd2;
            end
            
            if (valid_interrupts[1] && priority_values[1] > max_priority) begin
                max_priority = priority_values[1];
                curr_max_id = 3'd1;
            end
            
            if (valid_interrupts[0] && priority_values[0] > max_priority) begin
                max_priority = priority_values[0];
                curr_max_id = 3'd0;
            end
            
            // 设置输出
            if (|valid_interrupts && max_priority > 3'd0) begin
                highest_priority <= curr_max_id;
                interrupt_valid <= 1'b1;
            end
        end
    end
endmodule