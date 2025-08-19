//SystemVerilog
module prog_timer(
    input wire clk, rst,
    input wire [1:0] mode, // 00:off, 01:oneshot, 10:repeat, 11:pwm
    input wire [7:0] period,
    input wire [7:0] duty,
    input wire start,
    output reg timer_out
);
    localparam OFF=2'b00, ACTIVE=2'b01, COMPLETE=2'b10;
    reg [1:0] state, next;
    reg [7:0] count;
    reg [7:0] mult_result;
    reg [7:0] mult_a, mult_b;
    reg [3:0] mult_count;
    reg mult_done;
    wire [7:0] pwm_threshold;
    
    // Optimized multiplier using DSP-like structure
    always @(posedge clk) begin
        if (rst) begin
            mult_result <= 8'd0;
            mult_count <= 4'd0;
            mult_done <= 1'b0;
        end else begin
            if (mult_count == 4'd0) begin
                mult_result <= 8'd0;
                mult_count <= 4'd1;
                mult_done <= 1'b0;
            end else if (mult_count <= 4'd8) begin
                mult_result <= mult_result + (mult_b[mult_count-1] ? (mult_a << (mult_count-1)) : 8'd0);
                mult_count <= mult_count + 4'd1;
                mult_done <= (mult_count == 4'd8);
            end
        end
    end

    // Pre-calculate PWM threshold
    assign pwm_threshold = (period * duty) >> 8;

    always @(posedge clk) begin
        if (rst) begin
            state <= OFF;
            count <= 8'd0;
            timer_out <= 1'b0;
            mult_a <= 8'd0;
            mult_b <= 8'd0;
        end else begin
            state <= next;
            
            case (state)
                OFF: begin
                    count <= 8'd0;
                    timer_out <= 1'b0;
                    mult_a <= 8'd0;
                    mult_b <= 8'd0;
                end
                ACTIVE: begin
                    if (mode == 2'b11) begin // PWM mode
                        if (!mult_done) begin
                            mult_a <= count;
                            mult_b <= duty;
                        end else begin
                            count <= count + 8'd1;
                            timer_out <= (count < pwm_threshold);
                            mult_a <= 8'd0;
                            mult_b <= 8'd0;
                        end
                    end else begin
                        count <= count + 8'd1;
                        timer_out <= 1'b1;
                    end
                end
                COMPLETE: begin
                    count <= 8'd0;
                    timer_out <= 1'b0;
                    mult_a <= 8'd0;
                    mult_b <= 8'd0;
                end
            endcase
        end
    end
    
    always @(*) begin
        case (state)
            OFF: next = (|mode & start) ? ACTIVE : OFF;
            ACTIVE: next = (count >= period) ? ((mode[1]) ? ACTIVE : COMPLETE) : ACTIVE;
            COMPLETE: next = OFF;
            default: next = OFF;
        endcase
    end
endmodule