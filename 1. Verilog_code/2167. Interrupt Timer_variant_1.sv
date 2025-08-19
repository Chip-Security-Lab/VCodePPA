//SystemVerilog
module interrupt_timer #(parameter WIDTH = 32)(
    input clock, reset, enable,
    input [WIDTH-1:0] compare_val,
    output [WIDTH-1:0] count_out,
    output reg irq_out
);
    reg [WIDTH-1:0] counter;
    reg irq_pending;
    reg compare_match;
    
    // 将比较逻辑预先计算，减少关键路径
    always @(*) begin
        compare_match = (counter == compare_val);
    end
    
    always @(posedge clock) begin
        if (reset) begin
            counter <= {WIDTH{1'b0}};
            irq_pending <= 1'b0;
            irq_out <= 1'b0;
        end 
        else if (enable) begin
            // 拆分时序逻辑，均衡路径
            counter <= counter + 1'b1;
            
            // 使用预计算的比较结果
            if (compare_match) begin
                irq_pending <= 1'b1;
            end
            
            // 将复杂逻辑拆分，减少关键路径
            if (irq_pending & ~irq_out) begin
                irq_out <= 1'b1;
            end
            else if (irq_out) begin
                irq_out <= 1'b0;
                irq_pending <= 1'b0;
            end
        end
    end
    
    assign count_out = counter;
endmodule