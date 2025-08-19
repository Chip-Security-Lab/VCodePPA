//SystemVerilog
module duty_cycle_clk #(
    parameter HIGH_CYCLE = 2,
    parameter TOTAL_CYCLE = 4
)(
    input clk,
    input rstb,
    output clk_out
);
    // 优化流水线结构的计数器和时钟生成
    
    // 阶段1: 计数器逻辑
    reg [7:0] cycle_counter_stage1;
    reg count_max_flag;
    reg valid_stage1;
    
    // 阶段2: 输出生成
    reg [7:0] cycle_counter_stage2;
    reg clk_out_reg;
    reg valid_stage2;
    
    // 阶段1 - 优化的计数逻辑
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            cycle_counter_stage1 <= 8'd0;
            count_max_flag <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
            
            // 优化比较链 - 使用等于比较而非大于等于比较
            if (cycle_counter_stage1 == (TOTAL_CYCLE - 1)) begin
                cycle_counter_stage1 <= 8'd0;
                count_max_flag <= 1'b1;
            end else begin
                cycle_counter_stage1 <= cycle_counter_stage1 + 8'd1;
                count_max_flag <= 1'b0;
            end
        end
    end
    
    // 阶段2 - 优化的输出生成
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            cycle_counter_stage2 <= 8'd0;
            clk_out_reg <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            cycle_counter_stage2 <= cycle_counter_stage1;
            valid_stage2 <= valid_stage1;
            
            // 优化比较逻辑 - 使用非阻塞赋值并简化条件
            if (valid_stage1) begin
                // 优化比较链 - 直接使用比较结果
                clk_out_reg <= (cycle_counter_stage1 < HIGH_CYCLE);
            end
        end
    end
    
    // 优化输出逻辑 - 使用与门实现
    assign clk_out = valid_stage2 & clk_out_reg;
    
endmodule