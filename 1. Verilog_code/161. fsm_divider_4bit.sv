module fsm_divider_4bit (
    input clk,
    input reset,
    input [3:0] a,
    input [3:0] b,
    output reg [3:0] quotient,
    output reg [3:0] remainder
);
    reg [3:0] state;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
            state <= 0;
        end else begin
            case (state)
                0: begin
                    quotient <= a / b;
                    remainder <= a % b;
                    state <= 1;
                end
            endcase
        end
    end
endmodule
