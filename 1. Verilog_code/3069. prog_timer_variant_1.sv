//SystemVerilog
module prog_timer(
    input wire clk, rst,
    input wire [1:0] mode,     // 00:off, 01:oneshot, 10:repeat, 11:pwm
    input wire [7:0] period,
    input wire [7:0] duty,
    input wire start,
    output reg timer_out
);

    // State definitions
    localparam OFF=2'b00, ACTIVE=2'b01, COMPLETE=2'b10;
    
    // Pipeline registers
    reg [1:0] state_reg, next_state;
    reg [7:0] count_reg;
    reg [1:0] mode_reg;
    reg start_reg;
    reg [7:0] period_reg;
    reg [7:0] duty_reg;
    
    // Input pipeline stage
    always @(posedge clk) begin
        if (rst) begin
            mode_reg <= 2'b00;
            start_reg <= 1'b0;
            period_reg <= 8'd0;
            duty_reg <= 8'd0;
        end else begin
            mode_reg <= mode;
            start_reg <= start;
            period_reg <= period;
            duty_reg <= duty;
        end
    end
    
    // State machine pipeline stage
    always @(posedge clk) begin
        if (rst) begin
            state_reg <= OFF;
            count_reg <= 8'd0;
            timer_out <= 1'b0;
        end else begin
            state_reg <= next_state;
            
            case (state_reg)
                OFF: begin
                    count_reg <= 8'd0;
                    timer_out <= 1'b0;
                end
                ACTIVE: begin
                    if (count_reg >= period_reg) begin
                        count_reg <= 8'd0;
                    end else begin
                        count_reg <= count_reg + 8'd1;
                    end
                    
                    if (mode_reg == 2'b11) begin
                        timer_out <= (count_reg < duty_reg);
                    end else begin
                        timer_out <= 1'b1;
                    end
                end
                COMPLETE: begin
                    count_reg <= 8'd0;
                    timer_out <= 1'b0;
                end
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        case (state_reg)
            OFF: begin
                next_state = ((mode_reg != 2'b00) && start_reg) ? ACTIVE : OFF;
            end
            ACTIVE: begin
                if (count_reg >= period_reg) begin
                    next_state = (mode_reg == 2'b10 || mode_reg == 2'b11) ? ACTIVE : COMPLETE;
                end else begin
                    next_state = ACTIVE;
                end
            end
            COMPLETE: begin
                next_state = OFF;
            end
            default: begin
                next_state = OFF;
            end
        endcase
    end

endmodule