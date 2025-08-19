//SystemVerilog
module oneshot_timer (
    input wire clock,
    input wire reset,
    input wire trigger,
    input wire [15:0] duration,
    output wire pulse_out
);
    // 内部信号声明
    reg [15:0] count_r;
    reg active_r;
    reg prev_trigger_r;
    reg pulse_out_r;
    
    // 组合逻辑信号
    wire trigger_edge;
    wire timeout;
    wire [15:0] next_count;
    wire next_active;
    wire next_pulse_out;
    
    // 组合逻辑部分
    // 边沿检测逻辑
    assign trigger_edge = trigger & ~prev_trigger_r;
    
    // 超时检测逻辑
    assign timeout = (count_r == duration - 1'b1);
    
    // 下一状态逻辑
    assign next_count = (trigger_edge) ? 16'd0 :
                        (active_r && !timeout) ? count_r + 1'b1 : 
                        count_r;
                        
    assign next_active = (trigger_edge) ? 1'b1 :
                         (active_r && timeout) ? 1'b0 :
                         active_r;
                         
    assign next_pulse_out = (trigger_edge) ? 1'b1 :
                            (active_r && timeout) ? 1'b0 :
                            pulse_out_r;
    
    // 输出连接
    assign pulse_out = pulse_out_r;
    
    // 时序逻辑部分
    always @(posedge clock) begin
        if (reset) begin
            count_r <= 16'd0;
            active_r <= 1'b0;
            pulse_out_r <= 1'b0;
            prev_trigger_r <= 1'b0;
        end else begin
            count_r <= next_count;
            active_r <= next_active;
            pulse_out_r <= next_pulse_out;
            prev_trigger_r <= trigger;
        end
    end
endmodule