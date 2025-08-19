//SystemVerilog
module multi_cycle_divider (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);
    reg [7:0] dividend;
    reg [7:0] divisor;
    reg [3:0] count;
    reg [1:0] state;
    
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            count <= 0;
            dividend <= 0;
            divisor <= 0;
            quotient <= 0;
            remainder <= 0;
        end else begin
            case (state)
                IDLE: begin
                    state <= CALC;
                    count <= 0;
                    dividend <= a;
                    divisor <= b;
                end
                CALC: begin
                    if (count < 8) begin
                        count <= count + 1;
                        quotient <= dividend / divisor;
                        remainder <= dividend % divisor;
                    end else begin
                        state <= DONE;
                    end
                end
                DONE: begin
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule