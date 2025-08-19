//SystemVerilog
module staircase_gen(
    input clock,
    input reset_n,
    input [2:0] step_size,
    input [4:0] num_steps,
    output reg [7:0] staircase_out
);
    // 流水线级寄存器
    reg [2:0] step_size_r;
    reg [4:0] num_steps_r;
    reg [4:0] step_counter;
    reg [7:0] staircase;
    reg step_valid;
    
    // 阶段1: 参数寄存和输入缓冲
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            step_size_r <= 3'b000;
            num_steps_r <= 5'b00000;
            step_valid <= 1'b0;
        end else begin
            step_size_r <= step_size;
            num_steps_r <= num_steps;
            step_valid <= 1'b1;
        end
    end
    
    // 阶段2: 步进计数控制逻辑
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            step_counter <= 5'h00;
        end else if (step_valid) begin
            if (step_counter >= num_steps_r) begin
                step_counter <= 5'h00;
            end else begin
                step_counter <= step_counter + 5'h01;
            end
        end
    end
    
    // 阶段3: 波形计算与生成
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            staircase <= 8'h00;
        end else if (step_valid) begin
            if (step_counter >= num_steps_r) begin
                staircase <= 8'h00;
            end else begin
                staircase <= staircase + {5'b0, step_size_r};
            end
        end
    end
    
    // 输出寄存阶段
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            staircase_out <= 8'h00;
        end else begin
            staircase_out <= staircase;
        end
    end
endmodule