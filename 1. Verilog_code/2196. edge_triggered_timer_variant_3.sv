//SystemVerilog
module edge_triggered_timer #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire reset_n,
    input wire trigger,
    input wire [WIDTH-1:0] duration,
    output reg timer_active,
    output reg timeout
);
    reg [WIDTH-1:0] counter;
    reg trigger_r;
    reg trigger_r2;
    wire trigger_edge;
    
    // 寄存trigger信号，减少输入路径延迟
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            trigger_r <= 1'b0;
            trigger_r2 <= 1'b0;
        end else begin
            trigger_r <= trigger;
            trigger_r2 <= trigger_r;
        end
    end
    
    // 优化边沿检测逻辑，使用两级寄存器实现
    assign trigger_edge = trigger_r2 & ~trigger_r;
    
    // 流水线阶段1：处理比较逻辑
    reg compare_result;
    reg [WIDTH-1:0] counter_next;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            compare_result <= 1'b0;
            counter_next <= {WIDTH{1'b0}};
        end else begin
            // 预计算比较结果和下一个计数值
            compare_result <= (counter >= duration - 1);
            counter_next <= counter + 1'b1;
        end
    end
    
    // 流水线阶段2：更新状态和输出
    // 使用case结构替代if-else级联
    reg [1:0] state;
    parameter IDLE = 2'b00, COUNTING = 2'b01, EDGE_DETECTED = 2'b10;

    always @(*) begin
        if (trigger_edge)
            state = EDGE_DETECTED;
        else if (timer_active && compare_result)
            state = IDLE;
        else if (timer_active)
            state = COUNTING;
        else
            state = IDLE;
    end
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter <= {WIDTH{1'b0}};
            timer_active <= 1'b0;
            timeout <= 1'b0;
        end else begin
            case (state)
                EDGE_DETECTED: begin
                    counter <= {WIDTH{1'b0}};
                    timer_active <= 1'b1;
                    timeout <= 1'b0;
                end
                
                COUNTING: begin
                    counter <= counter_next;
                    timer_active <= 1'b1;
                    timeout <= 1'b0;
                end
                
                IDLE: begin
                    counter <= counter;
                    timer_active <= 1'b0;
                    timeout <= (timer_active && compare_result) ? 1'b1 : timeout;
                end
                
                default: begin
                    counter <= counter;
                    timer_active <= timer_active;
                    timeout <= timeout;
                end
            endcase
        end
    end
endmodule