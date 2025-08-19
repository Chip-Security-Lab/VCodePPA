//SystemVerilog
module pulse_width_measure #(
    parameter COUNTER_WIDTH = 32
)(
    input clk,
    input pulse_in,
    output reg [COUNTER_WIDTH-1:0] width_count
);
    reg last_state;
    reg measuring;
    
    // 创建状态变量用于case语句
    reg [1:0] pulse_transition;
    
    always @(posedge clk) begin
        last_state <= pulse_in;
        
        // 组合脉冲当前状态和上一状态形成转换标识
        pulse_transition = {pulse_in, last_state};
        
        case (pulse_transition)
            2'b10:  begin // 上升沿: 当前为1，上一状态为0
                measuring <= 1;
                width_count <= 0;
            end
            
            2'b01:  begin // 下降沿: 当前为0，上一状态为1
                measuring <= 0;
            end
            
            default: begin // 其他情况: 包括稳定状态00和11
                if (measuring) begin
                    width_count <= width_count + 1;
                end
            end
        endcase
    end
endmodule