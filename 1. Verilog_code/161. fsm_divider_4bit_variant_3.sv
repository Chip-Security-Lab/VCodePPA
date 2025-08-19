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
    reg [3:0] dividend;
    reg [3:0] divisor;
    reg [3:0] temp_quotient;
    reg [3:0] temp_remainder;
    reg [2:0] counter;
    wire [3:0] next_remainder;
    wire [3:0] next_dividend;
    wire [3:0] next_quotient;
    wire [2:0] next_counter;
    wire [3:0] next_state;

    // 组合逻辑计算下一状态
    assign next_remainder = (counter < 4) ? {temp_remainder[2:0], dividend[3]} : temp_remainder;
    assign next_dividend = (counter < 4) ? {dividend[2:0], 1'b0} : dividend;
    assign next_quotient = (counter < 4) ? 
        ((temp_remainder >= divisor) ? {temp_quotient[2:0], 1'b1} : {temp_quotient[2:0], 1'b0}) : 
        temp_quotient;
    assign next_counter = (counter < 4) ? counter + 1 : counter;
    assign next_state = (counter == 4) ? 4'b0000 : 4'b0001;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 4'b0;
            remainder <= 4'b0;
            state <= 4'b0;
            dividend <= 4'b0;
            divisor <= 4'b0;
            temp_quotient <= 4'b0;
            temp_remainder <= 4'b0;
            counter <= 3'b0;
        end else begin
            case (state)
                4'b0000: begin
                    dividend <= a;
                    divisor <= b;
                    temp_quotient <= 4'b0;
                    temp_remainder <= 4'b0;
                    counter <= 3'b0;
                    state <= 4'b0001;
                end
                4'b0001: begin
                    temp_remainder <= next_remainder;
                    dividend <= next_dividend;
                    temp_quotient <= next_quotient;
                    counter <= next_counter;
                    state <= next_state;
                    
                    if (counter == 4) begin
                        quotient <= temp_quotient;
                        remainder <= temp_remainder;
                    end
                end
            endcase
        end
    end
endmodule