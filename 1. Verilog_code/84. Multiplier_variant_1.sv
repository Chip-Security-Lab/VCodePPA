//SystemVerilog
module Multiplier4(
    input clk,
    input rst_n,
    input [3:0] a,
    input [3:0] b,
    input req,
    output reg ack,
    output reg [7:0] result
);

    reg [7:0] acc;
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            acc <= 8'd0;
            ack <= 1'b0;
            result <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (req) begin
                        state <= CALC;
                        acc <= 8'd0;
                        ack <= 1'b0;
                    end
                end
                CALC: begin
                    acc <= a * b;
                    state <= DONE;
                end
                DONE: begin
                    result <= acc;
                    ack <= 1'b1;
                    if (!req) begin
                        state <= IDLE;
                        ack <= 1'b0;
                    end
                end
            endcase
        end
    end

endmodule