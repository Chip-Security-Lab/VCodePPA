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
    reg [7:0] x, y;  // 8-bit for intermediate calculations
    reg [3:0] iter;
    reg [7:0] f;     // scaling factor
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
            state <= 0;
            x <= 0;
            y <= 0;
            iter <= 0;
            f <= 0;
        end else begin
            case (state)
                0: begin
                    // Initialize
                    x <= {4'b0, a};
                    y <= {4'b0, b};
                    f <= 8'b00010000;  // Initial scaling factor
                    iter <= 0;
                    state <= 1;
                end
                1: begin
                    // Goldschmidt iteration
                    if (iter < 3) begin
                        x <= x * f;
                        y <= y * f;
                        f <= 8'b00010000 - y[3:0];
                        iter <= iter + 1;
                    end else begin
                        quotient <= x[7:4];
                        remainder <= a - (x[7:4] * b);
                        state <= 2;
                    end
                end
                2: begin
                    state <= 0;
                end
            endcase
        end
    end
endmodule