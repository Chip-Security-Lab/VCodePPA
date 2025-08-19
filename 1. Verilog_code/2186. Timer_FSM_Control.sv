module Timer_FSM_Control (
    input clk, rst, trigger,
    output reg done
);
    // 使用参数替代enum类型
    parameter IDLE = 1'b0, COUNTING = 1'b1;
    
    reg state;
    reg [7:0] cnt;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            cnt <= 8'h00;
            done <= 1'b0;
        end else case(state)
            IDLE: if (trigger) begin
                state <= COUNTING;
                cnt <= 8'd100;
                done <= 1'b0;
            end
            COUNTING: begin
                cnt <= cnt - 8'd1;
                done <= (cnt == 8'd1);
                if (cnt == 8'd0) state <= IDLE;
            end
            default: state <= IDLE;
        endcase
    end
endmodule