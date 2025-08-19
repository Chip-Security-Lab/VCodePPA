module nested_icmu #(
    parameter NEST_LEVELS = 4,
    parameter WIDTH = 32
)(
    input clk, reset_n,
    input [WIDTH-1:0] irq,
    input [WIDTH*4-1:0] irq_priority_flat, // 修改为扁平化数组
    input complete,
    output reg [4:0] active_irq,
    output reg [4:0] stack_ptr,
    output reg ctx_switch
);
    reg [4:0] irq_stack [0:NEST_LEVELS-1];
    reg [3:0] pri_stack [0:NEST_LEVELS-1];
    reg [3:0] current_priority;
    wire [3:0] irq_priority [0:WIDTH-1]; // 内部数组
    integer i;
    reg found_irq; // 添加标志位以避免使用break
    
    // 从扁平数组提取优先级
    genvar g;
    generate
        for (g = 0; g < WIDTH; g = g + 1) begin: prio_map
            assign irq_priority[g] = irq_priority_flat[g*4+3:g*4];
        end
    endgenerate
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            stack_ptr <= 5'd0;
            active_irq <= 5'd31;
            current_priority <= 4'd0;
            ctx_switch <= 1'b0;
            found_irq <= 1'b0;
            
            // 初始化堆栈
            for (i = 0; i < NEST_LEVELS; i = i + 1) begin
                irq_stack[i] <= 5'd0;
                pri_stack[i] <= 4'd0;
            end
        end else begin
            ctx_switch <= 1'b0;
            found_irq <= 1'b0;
            
            // 处理中断完成
            if (complete && stack_ptr > 0) begin
                stack_ptr <= stack_ptr - 1'b1;
                if (stack_ptr > 1) begin
                    active_irq <= irq_stack[stack_ptr-2];
                    current_priority <= pri_stack[stack_ptr-2];
                end else begin
                    active_irq <= 5'd31; // 无活动中断
                    current_priority <= 4'd0;
                end
                ctx_switch <= 1'b1;
            end
            
            // 使用组合逻辑查找高优先级中断
            if (!ctx_switch) begin // 避免同时设置ctx_switch
                for (i = 0; i < WIDTH; i = i + 1) begin
                    if (irq[i] && irq_priority[i] > current_priority &&
                        stack_ptr < NEST_LEVELS && !found_irq) begin
                        irq_stack[stack_ptr] <= i[4:0];
                        pri_stack[stack_ptr] <= irq_priority[i];
                        stack_ptr <= stack_ptr + 1'b1;
                        active_irq <= i[4:0];
                        current_priority <= irq_priority[i];
                        ctx_switch <= 1'b1;
                        found_irq <= 1'b1; // 使用标志位而不是break
                    end
                end
            end
        end
    end
endmodule