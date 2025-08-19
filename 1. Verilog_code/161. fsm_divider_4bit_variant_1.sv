//SystemVerilog
module fsm_divider_4bit (
    input clk,
    input reset,
    input [3:0] a,
    input [3:0] b,
    output reg [3:0] quotient,
    output reg [3:0] remainder
);

    reg [3:0] state;
    reg [3:0] x_prev;
    reg [3:0] x_next;
    reg [3:0] iteration_count;
    reg [7:0] temp_product;
    reg [7:0] temp_sub;
    reg [7:0] temp_mul;
    reg [7:0] temp_add;
    reg [7:0] temp_shift;
    reg [7:0] temp_round;
    reg [3:0] final_quotient;
    reg [3:0] final_remainder;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
            state <= 0;
            x_prev <= 0;
            x_next <= 0;
            iteration_count <= 0;
            temp_product <= 0;
            temp_sub <= 0;
            temp_mul <= 0;
            temp_add <= 0;
            temp_shift <= 0;
            temp_round <= 0;
            final_quotient <= 0;
            final_remainder <= 0;
        end else begin
            case (state)
                0: begin
                    // Initial guess: x0 = 1/b
                    x_prev <= (b == 0) ? 4'b1111 : (8'b1 << 4) / b;
                    iteration_count <= 0;
                    state <= 1;
                end
                1: begin
                    // Newton-Raphson iteration: x_{n+1} = x_n * (2 - b * x_n)
                    temp_product <= b * x_prev;
                    state <= 2;
                end
                2: begin
                    temp_sub <= (8'b10 << 4) - temp_product;
                    state <= 3;
                end
                3: begin
                    temp_mul <= x_prev * temp_sub;
                    state <= 4;
                end
                4: begin
                    temp_shift <= temp_mul >> 4;
                    x_next <= temp_shift[3:0];
                    iteration_count <= iteration_count + 1;
                    state <= 5;
                end
                5: begin
                    if (iteration_count < 2 || x_prev != x_next) begin
                        x_prev <= x_next;
                        state <= 1;
                    end else begin
                        state <= 6;
                    end
                end
                6: begin
                    // Calculate final quotient and remainder
                    temp_mul <= a * x_next;
                    state <= 7;
                end
                7: begin
                    temp_shift <= temp_mul >> 4;
                    temp_round <= temp_shift + (temp_mul[3] ? 8'b1 : 8'b0);
                    state <= 8;
                end
                8: begin
                    final_quotient <= temp_round[3:0];
                    temp_mul <= final_quotient * b;
                    state <= 9;
                end
                9: begin
                    final_remainder <= a - temp_mul[3:0];
                    state <= 10;
                end
                10: begin
                    quotient <= final_quotient;
                    remainder <= final_remainder;
                    state <= 0;
                end
            endcase
        end
    end
endmodule