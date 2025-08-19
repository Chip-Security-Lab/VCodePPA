//SystemVerilog
module sync_dc_blocker #(
    parameter WIDTH = 16
)(
    input wire clk, 
    input wire reset,
    input wire [WIDTH-1:0] signal_in,
    input wire input_valid,
    output wire input_ready,
    output wire [WIDTH-1:0] signal_out,
    output wire output_valid,
    input wire output_ready
);
    // 流水线寄存器和控制信号
    reg [WIDTH-1:0] prev_in_stage1;
    reg [WIDTH-1:0] prev_out_stage1;
    reg [WIDTH-1:0] signal_in_stage1;
    reg valid_stage1;
    
    reg [WIDTH-1:0] diff_stage2;
    reg [WIDTH-1:0] scaled_prev_out_stage2;
    reg valid_stage2;
    
    reg [WIDTH-1:0] signal_out_reg;
    reg valid_out_reg;
    
    // 流水线控制逻辑
    wire stage1_ready;
    wire stage2_ready;
    
    assign stage1_ready = !valid_stage2 || stage2_ready;
    assign stage2_ready = !valid_out_reg || output_ready;
    assign input_ready = !valid_stage1 || stage1_ready;
    
    assign output_valid = valid_out_reg;
    assign signal_out = signal_out_reg;
    
    // 流水线阶段1：存储输入和状态
    always @(posedge clk) begin
        if (reset) begin
            signal_in_stage1 <= 0;
            prev_in_stage1 <= 0;
            prev_out_stage1 <= 0;
            valid_stage1 <= 0;
        end else if (input_ready && input_valid) begin
            signal_in_stage1 <= signal_in;
            prev_in_stage1 <= prev_in_stage1;  // 更新发生在阶段3
            prev_out_stage1 <= prev_out_stage1; // 更新发生在阶段3
            valid_stage1 <= 1;
        end else if (stage1_ready) begin
            valid_stage1 <= 0;
        end
    end
    
    // 流水线阶段2：执行计算前半部分
    always @(posedge clk) begin
        if (reset) begin
            diff_stage2 <= 0;
            scaled_prev_out_stage2 <= 0;
            valid_stage2 <= 0;
        end else if (valid_stage1 && stage1_ready) begin
            diff_stage2 <= signal_in_stage1 - prev_in_stage1;
            scaled_prev_out_stage2 <= (prev_out_stage1 * 7) >> 3;
            valid_stage2 <= 1;
        end else if (stage2_ready) begin
            valid_stage2 <= 0;
        end
    end
    
    // 流水线阶段3：完成计算并更新状态
    always @(posedge clk) begin
        if (reset) begin
            signal_out_reg <= 0;
            valid_out_reg <= 0;
            prev_in_stage1 <= 0;
            prev_out_stage1 <= 0;
        end else if (valid_stage2 && stage2_ready) begin
            signal_out_reg <= diff_stage2 + scaled_prev_out_stage2;
            valid_out_reg <= 1;
            
            // 更新状态变量，用于下一个计算周期
            prev_in_stage1 <= signal_in_stage1;
            prev_out_stage1 <= diff_stage2 + scaled_prev_out_stage2;
        end else if (output_ready) begin
            valid_out_reg <= 0;
        end
    end
endmodule