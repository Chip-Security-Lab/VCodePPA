//SystemVerilog
module jitter_clock(
    input clk_in,
    input rst,
    input [2:0] jitter_amount,
    input jitter_en,
    output reg clk_out
);
    reg [2:0] jitter_value;
    reg [2:0] jitter_current;
    reg [4:0] counter_current;
    reg [4:0] counter_next;
    reg clk_toggle;
    
    // 阶段1: 优化抖动计算逻辑
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            jitter_value <= 3'd0;
            jitter_current <= 3'd0;
        end else begin
            jitter_value <= jitter_en ? {^counter_current, counter_current[1:0]} & jitter_amount : 3'd0;
            jitter_current <= jitter_value;
        end
    end
    
    // 阶段2: 优化计数器更新逻辑
    always @(*) begin
        // 直接使用比较判断替代case语句
        if (counter_current + jitter_current >= 5'd16) begin
            counter_next = 5'd0;
            clk_toggle = 1'b1;
        end else begin
            counter_next = counter_current + 5'd1;
            clk_toggle = 1'b0;
        end
    end
    
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter_current <= 5'd0;
        end else begin
            counter_current <= counter_next;
        end
    end
    
    // 阶段3: 优化时钟输出生成
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            clk_out <= 1'b0;
        end else if (clk_toggle) begin
            clk_out <= ~clk_out;
        end
    end
    
endmodule