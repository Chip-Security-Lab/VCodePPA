//SystemVerilog
module interrupt_timer #(parameter WIDTH = 32)(
    input clock, reset, enable,
    input [WIDTH-1:0] compare_val,
    output [WIDTH-1:0] count_out,
    output reg irq_out
);
    reg [WIDTH-1:0] counter;
    reg irq_pending;
    wire counter_match;
    
    // 使用预比较逻辑减少关键路径延迟
    assign counter_match = (counter == compare_val - 1'b1);
    
    always @(posedge clock) begin
        if (reset) begin
            counter <= {WIDTH{1'b0}};
            irq_pending <= 1'b0;
            irq_out <= 1'b0;
        end 
        else if (enable) begin
            counter <= counter + 1'b1;
            
            // 优化比较逻辑，提前一个周期做比较
            if (counter_match) 
                irq_pending <= 1'b1;
                
            // 分离中断逻辑，改善时序
            irq_out <= irq_pending & ~irq_out;
            
            // 确保中断清除逻辑清晰
            if (irq_out) 
                irq_pending <= 1'b0;
        end
    end
    
    assign count_out = counter;
endmodule