//SystemVerilog
module usb_low_power_ctrl(
    input clk_48mhz,
    input reset_n,
    input bus_activity,
    input suspend_req,
    input resume_req,
    output reg suspend_state,
    output reg clk_en,
    output reg pll_en
);
    localparam ACTIVE = 2'b00, IDLE = 2'b01, SUSPEND = 2'b10, RESUME = 2'b11;
    reg [1:0] state;
    reg [15:0] idle_counter;
    wire [15:0] next_idle_counter;
    
    // 使用优化的前缀加法器实现idle_counter加1操作
    optimized_adder adder_inst(
        .a(idle_counter),
        .sum(next_idle_counter)
    );
    
    // 提前计算状态转换条件，优化比较链
    wire active_to_idle = (!bus_activity) && (idle_counter >= 16'd3000 || suspend_req);
    wire idle_to_active = bus_activity;
    wire idle_to_suspend = (!bus_activity) && (idle_counter >= 16'd20000);
    wire suspend_to_resume = bus_activity || resume_req;
    wire resume_complete = idle_counter >= 16'd1000;
    
    always @(posedge clk_48mhz or negedge reset_n) begin
        if (!reset_n) begin
            state <= ACTIVE;
            idle_counter <= 16'd0;
            suspend_state <= 1'b0;
            clk_en <= 1'b1;
            pll_en <= 1'b1;
        end else begin
            // 默认保持计数器不变
            idle_counter <= idle_counter;
            
            case (state)
                ACTIVE: begin
                    if (bus_activity)
                        idle_counter <= 16'd0;
                    else if (!active_to_idle)
                        idle_counter <= next_idle_counter;
                        
                    if (active_to_idle)
                        state <= IDLE;
                end
                
                IDLE: begin
                    if (idle_to_active) begin
                        state <= ACTIVE;
                        idle_counter <= 16'd0;
                    end else if (idle_to_suspend) begin
                        state <= SUSPEND;
                        suspend_state <= 1'b1;
                        clk_en <= 1'b0;
                        pll_en <= 1'b0;
                    end else
                        idle_counter <= next_idle_counter;
                end
                
                SUSPEND: begin
                    if (suspend_to_resume) begin
                        state <= RESUME;
                        pll_en <= 1'b1;
                        idle_counter <= 16'd0; // 重置计数器
                    end
                end
                
                RESUME: begin
                    if (!resume_complete)
                        idle_counter <= next_idle_counter;
                    else begin
                        state <= ACTIVE;
                        suspend_state <= 1'b0;
                        clk_en <= 1'b1;
                        idle_counter <= 16'd0;
                    end
                end
            endcase
        end
    end
endmodule

// 优化的加法器模块 - 更高效的实现
module optimized_adder(
    input [15:0] a,
    output [15:0] sum
);
    // 简单的加1操作，减少电路复杂度，优化时序
    assign sum = a + 16'd1;
endmodule