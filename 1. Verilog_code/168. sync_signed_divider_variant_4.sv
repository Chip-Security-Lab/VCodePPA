//SystemVerilog
module sync_signed_divider (
    input clk,
    input reset,
    input valid_in,
    input signed [7:0] a,
    input signed [7:0] b,
    output reg ready_out,
    output reg valid_out,
    output reg signed [7:0] quotient,
    output reg signed [7:0] remainder
);

    reg [1:0] state;
    reg signed [7:0] a_reg;
    reg signed [7:0] b_reg;
    reg signed [7:0] quotient_reg;
    reg signed [7:0] remainder_reg;
    reg [3:0] count;
    reg signed [15:0] dividend;
    reg signed [7:0] divisor;
    reg signed [7:0] quotient_temp;
    reg signed [7:0] remainder_temp;
    
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            ready_out <= 1'b1;
            valid_out <= 1'b0;
            quotient <= 0;
            remainder <= 0;
            a_reg <= 0;
            b_reg <= 0;
            quotient_reg <= 0;
            remainder_reg <= 0;
            count <= 0;
            dividend <= 0;
            divisor <= 0;
            quotient_temp <= 0;
            remainder_temp <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (valid_in) begin
                        state <= CALC;
                        ready_out <= 1'b0;
                        a_reg <= a;
                        b_reg <= b;
                        count <= 0;
                        dividend <= {a_reg, 8'b0};
                        divisor <= b_reg;
                        quotient_temp <= 0;
                        remainder_temp <= 0;
                    end
                end
                
                CALC: begin
                    if (count < 8) begin
                        count <= count + 1;
                        dividend <= {dividend[14:0], 1'b0};
                        if (dividend[15:8] >= divisor) begin
                            dividend[15:8] <= dividend[15:8] - divisor;
                            quotient_temp <= {quotient_temp[6:0], 1'b1};
                        end else begin
                            quotient_temp <= {quotient_temp[6:0], 1'b0};
                        end
                    end else begin
                        state <= DONE;
                        quotient_reg <= quotient_temp;
                        remainder_reg <= dividend[15:8];
                    end
                end
                
                DONE: begin
                    state <= IDLE;
                    valid_out <= 1'b1;
                    ready_out <= 1'b1;
                    quotient <= quotient_reg;
                    remainder <= remainder_reg;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule