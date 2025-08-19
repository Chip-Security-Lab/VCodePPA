//SystemVerilog
module prescaler_timer (
    input wire clk,
    input wire rst_n,
    input wire [3:0] prescale_sel,
    input wire [15:0] period,
    output reg tick_out
);
    // 将组合逻辑提前到寄存器前计算
    wire [15:0] prescale_threshold;
    assign prescale_threshold = (prescale_sel == 4'd0) ? 16'd0 :
                               (prescale_sel == 4'd1) ? 16'd1 :
                               (prescale_sel == 4'd2) ? 16'd3 :
                               ((16'd1 << prescale_sel) - 16'd1);
    
    reg [15:0] prescale_count;
    reg [15:0] timer_count;
    
    // 预计算下一个状态的值，减少关键路径延迟
    wire prescale_threshold_reached;
    wire [15:0] next_prescale_count;
    wire next_tick_enable;
    
    assign prescale_threshold_reached = (prescale_sel == 4'd0) || (prescale_count >= prescale_threshold);
    assign next_prescale_count = prescale_threshold_reached ? 16'h0000 : (prescale_count + 16'd1);
    assign next_tick_enable = prescale_threshold_reached ? 1'b1 : 1'b0;
    
    // 优化的Prescaler逻辑 - 寄存器移动到组合逻辑后
    reg tick_enable;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prescale_count <= 16'h0000;
            tick_enable <= 1'b0;
        end else begin
            prescale_count <= next_prescale_count;
            tick_enable <= next_tick_enable;
        end
    end
    
    // 预计算Timer的下一个状态
    wire period_reached;
    wire [15:0] next_timer_count;
    wire next_tick_out;
    
    assign period_reached = (timer_count >= period - 16'd1);
    assign next_timer_count = period_reached ? 16'h0000 : (timer_count + 16'd1);
    assign next_tick_out = period_reached ? 1'b1 : 1'b0;
    
    // 优化的Timer逻辑 - 寄存器移到组合逻辑后，减少关键路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_count <= 16'h0000;
            tick_out <= 1'b0;
        end else if (tick_enable) begin
            timer_count <= next_timer_count;
            tick_out <= next_tick_out;
        end
    end
endmodule