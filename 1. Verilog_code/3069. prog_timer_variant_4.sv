//SystemVerilog
module prog_timer(
    input wire clk, rst,
    input wire [1:0] mode,
    input wire [7:0] period,
    input wire [7:0] duty,
    input wire start,
    output reg timer_out
);
    localparam OFF=2'b00, ACTIVE=2'b01, COMPLETE=2'b10;
    reg [1:0] state, next_state;
    reg [7:0] count, next_count;
    reg next_timer_out;
    
    // 预计算控制信号
    wire mode_valid = (mode != 2'b00);
    wire mode_repeat = (mode == 2'b10);
    wire mode_pwm = (mode == 2'b11);
    wire count_complete = (count >= period);
    wire pwm_active = (count < duty);
    
    // 组合逻辑优化
    always @(*) begin
        case (state)
            OFF: begin
                next_state = (mode_valid && start) ? ACTIVE : OFF;
                next_count = 8'd0;
                next_timer_out = 1'b0;
            end
            ACTIVE: begin
                if (count_complete) begin
                    next_state = (mode_repeat || mode_pwm) ? ACTIVE : COMPLETE;
                    next_count = 8'd0;
                end else begin
                    next_state = ACTIVE;
                    next_count = count + 8'd1;
                end
                next_timer_out = mode_pwm ? pwm_active : 1'b1;
            end
            COMPLETE: begin
                next_state = OFF;
                next_count = 8'd0;
                next_timer_out = 1'b0;
            end
            default: begin
                next_state = OFF;
                next_count = 8'd0;
                next_timer_out = 1'b0;
            end
        endcase
    end
    
    // 时序逻辑
    always @(posedge clk) begin
        if (rst) begin
            state <= OFF;
            count <= 8'd0;
            timer_out <= 1'b0;
        end else begin
            state <= next_state;
            count <= next_count;
            timer_out <= next_timer_out;
        end
    end
endmodule