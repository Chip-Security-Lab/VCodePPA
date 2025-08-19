//SystemVerilog
module power_on_reset_gen(
    input wire clk,
    input wire power_stable,
    output reg por_reset_n
);
    // 状态寄存器
    reg [2:0] por_counter;
    reg power_stable_meta;
    reg power_stable_sync;
    
    // 中间信号
    wire counter_max;
    reg reset_pending;
    
    // 处理输入信号的亚稳态
    always @(posedge clk) begin
        power_stable_meta <= power_stable;
        power_stable_sync <= power_stable_meta;
    end
    
    // 比较优化：使用等式检查而非不等式范围检查
    assign counter_max = (por_counter == 3'b111);
    
    // 计数器逻辑和状态检测
    always @(posedge clk) begin
        if (!power_stable_sync) begin
            // 如果电源不稳定，重置计数器
            por_counter <= 3'b000;
            reset_pending <= 1'b0;
        end else if (!counter_max) begin
            // 如果计数器未达到最大值，递增
            por_counter <= por_counter + 1'b1;
            reset_pending <= 1'b0;
        end else begin
            // 计数器达到最大值
            por_counter <= por_counter;
            reset_pending <= 1'b1;
        end
    end
    
    // 输出逻辑
    always @(posedge clk) begin
        por_reset_n <= power_stable_sync & reset_pending;
    end
endmodule