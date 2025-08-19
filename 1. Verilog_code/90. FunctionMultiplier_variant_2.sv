//SystemVerilog
module FunctionMultiplier(
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    input [3:0] m,
    input [3:0] n,
    output reg [7:0] res,
    output reg res_valid
);

    reg [7:0] result;
    reg state;
    localparam IDLE = 1'b0;
    localparam CALC = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ready <= 1'b1;
            res_valid <= 1'b0;
            result <= 8'd0;
        end else if (state == IDLE && valid && ready) begin
            state <= CALC;
            ready <= 1'b0;
            result <= m * n;
        end else if (state == CALC) begin
            res <= result;
            res_valid <= 1'b1;
            state <= IDLE;
            ready <= 1'b1;
        end
    end

endmodule