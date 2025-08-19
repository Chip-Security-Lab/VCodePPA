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
    
    always @(posedge clk)
        if (rst) begin
            state <= OFF;
            count <= 8'd0;
            timer_out <= 1'b0;
        end else begin
            state <= next;
            
            case (state)
                OFF: begin
                    count <= 8'd0;
                    timer_out <= 1'b0;
                end
                ACTIVE: begin
                    count <= count + 8'd1;
                    if (mode == 2'b11) // PWM mode
                        timer_out <= (count < duty);
                    else
                        timer_out <= 1'b1;
                end
                COMPLETE: begin
                    count <= 8'd0;
                    timer_out <= 1'b0;
                end
            endcase
        end
    
    always @(*) begin
        case (state)
            OFF: next = ((mode != 2'b00) && start) ? ACTIVE : OFF;
            ACTIVE: begin
                if (count >= period)
                    next = (mode == 2'b10 || mode == 2'b11) ? ACTIVE : COMPLETE;
                else
                    next = ACTIVE;
            end
            COMPLETE: next = OFF;
            default: next = OFF;
        endcase
    end
endmodule