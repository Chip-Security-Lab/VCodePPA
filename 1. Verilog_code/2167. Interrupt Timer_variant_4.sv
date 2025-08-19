//SystemVerilog
module interrupt_timer #(parameter WIDTH = 32)(
    input clock, reset, enable,
    input [WIDTH-1:0] compare_val,
    output [WIDTH-1:0] count_out,
    output reg irq_out
);
    // 流水线阶段1 - 计数器逻辑
    reg [WIDTH-1:0] counter_stage1;
    reg counter_valid_stage1;
    reg [WIDTH-1:0] compare_val_stage1;
    
    // 流水线阶段2 - 比较逻辑
    reg [WIDTH-1:0] counter_stage2;
    reg compare_match_stage2;
    reg counter_valid_stage2;
    
    // 流水线阶段3 - 中断生成逻辑
    reg irq_pending;
    
    // 阶段1: 计数器递增
    always @(posedge clock) begin
        if (reset) begin
            counter_stage1 <= {WIDTH{1'b0}};
            counter_valid_stage1 <= 1'b0;
            compare_val_stage1 <= {WIDTH{1'b0}};
        end else if (enable) begin
            counter_stage1 <= counter_stage1 + 1'b1;
            counter_valid_stage1 <= 1'b1;
            compare_val_stage1 <= compare_val;
        end
    end
    
    // 阶段2: 比较逻辑
    always @(posedge clock) begin
        if (reset) begin
            counter_stage2 <= {WIDTH{1'b0}};
            compare_match_stage2 <= 1'b0;
            counter_valid_stage2 <= 1'b0;
        end else if (enable) begin
            counter_stage2 <= counter_stage1;
            compare_match_stage2 <= (counter_stage1 == compare_val_stage1) && counter_valid_stage1;
            counter_valid_stage2 <= counter_valid_stage1;
        end
    end
    
    // 阶段3: 中断生成
    always @(posedge clock) begin
        if (reset) begin
            irq_pending <= 1'b0;
            irq_out <= 1'b0;
        end else if (enable) begin
            if (compare_match_stage2) 
                irq_pending <= 1'b1;
                
            irq_out <= irq_pending & ~irq_out & counter_valid_stage2;
            
            if (irq_out) 
                irq_pending <= 1'b0;
        end
    end
    
    // 输出计数器值
    assign count_out = counter_stage1;
    
endmodule