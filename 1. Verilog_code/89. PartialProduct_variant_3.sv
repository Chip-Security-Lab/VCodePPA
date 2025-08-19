//SystemVerilog
module PartialProduct(
    input clk,
    input rst_n,
    input [3:0] a,
    input [3:0] b,
    input valid,
    output reg ready,
    output reg [7:0] result
);

    reg [7:0] pp0, pp1, pp2, pp3;
    reg [7:0] temp_result;
    reg state;
    localparam IDLE = 1'b0;
    localparam CALC = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ready <= 1'b1;
            result <= 8'b0;
            temp_result <= 8'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (valid && ready) begin
                        pp0 <= b[0] ? {4'b0, a} : 0;
                        pp1 <= b[1] ? {3'b0, a, 1'b0} : 0;
                        pp2 <= b[2] ? {2'b0, a, 2'b0} : 0;
                        pp3 <= b[3] ? {1'b0, a, 3'b0} : 0;
                        state <= CALC;
                        ready <= 1'b0;
                    end
                end
                CALC: begin
                    temp_result <= pp0 + pp1 + pp2 + pp3;
                    result <= temp_result;
                    ready <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule