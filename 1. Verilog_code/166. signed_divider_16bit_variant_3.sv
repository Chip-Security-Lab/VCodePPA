//SystemVerilog
module signed_divider_16bit (
    input wire clk,
    input wire rst_n,
    input signed [15:0] a,
    input signed [15:0] b,
    output reg signed [15:0] quotient,
    output reg signed [15:0] remainder
);

    // Internal signals
    reg signed [15:0] a_reg, b_reg;
    reg a_sign, b_sign;
    reg [15:0] a_abs, b_abs;
    reg [15:0] x, y;
    reg [15:0] x_next, y_next;
    reg [3:0] iter_cnt;
    reg div_done;
    
    // State machine states
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    reg [1:0] state, next_state;

    // Main state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: next_state = CALC;
            CALC: next_state = (iter_cnt == 4'd8) ? DONE : CALC;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Data path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 16'd0;
            b_reg <= 16'd0;
            a_sign <= 1'b0;
            b_sign <= 1'b0;
            a_abs <= 16'd0;
            b_abs <= 16'd0;
            x <= 16'd0;
            y <= 16'd0;
            iter_cnt <= 4'd0;
            quotient <= 16'd0;
            remainder <= 16'd0;
            div_done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    a_reg <= a;
                    b_reg <= b;
                    a_sign <= a[15];
                    b_sign <= b[15];
                    a_abs <= a[15] ? -a : a;
                    b_abs <= b[15] ? -b : b;
                    x <= a[15] ? -a : a;
                    y <= b[15] ? -b : b;
                    iter_cnt <= 4'd0;
                    div_done <= 1'b0;
                end

                CALC: begin
                    x <= x_next;
                    y <= y_next;
                    iter_cnt <= iter_cnt + 1'b1;
                end

                DONE: begin
                    quotient <= (a_sign ^ b_sign) ? -x : x;
                    remainder <= a_reg - shift_add_multiply(quotient, b_reg);
                    div_done <= 1'b1;
                end
            endcase
        end
    end

    // Goldschmidt iteration with shift-and-add multiplier
    always @(*) begin
        x_next = x;
        y_next = y;
        
        if (state == CALC) begin
            // Goldschmidt iteration formula using shift-and-add multiplier
            x_next = shift_add_multiply(x, (16'd2 - y));
            y_next = shift_add_multiply(y, (16'd2 - y));
        end
    end

    // Shift-and-add multiplier function
    function [15:0] shift_add_multiply;
        input [15:0] multiplicand;
        input [15:0] multiplier;
        reg [15:0] result;
        reg [15:0] temp;
        integer i;
        begin
            result = 16'd0;
            temp = multiplicand;
            
            for (i = 0; i < 16; i = i + 1) begin
                if (multiplier[i]) begin
                    result = result + temp;
                end
                temp = {temp[14:0], 1'b0}; // Shift left by 1
            end
            
            shift_add_multiply = result;
        end
    endfunction

endmodule