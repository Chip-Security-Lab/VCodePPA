//SystemVerilog
module LUTDiv(
    input clk,
    input rst_n,
    input valid_i,
    output reg ready_o,
    input [3:0] x,
    input [3:0] y,
    output reg valid_o,
    input ready_i,
    output reg [7:0] q
);

    reg [7:0] product;
    reg [3:0] counter;
    reg [7:0] multiplicand;
    reg [7:0] multiplier;
    reg [7:0] result;
    reg state;
    reg next_state;

    localparam IDLE = 1'b0;
    localparam CALC = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ready_o <= 1'b0;
            valid_o <= 1'b0;
            q <= 8'h00;
        end else begin
            state <= next_state;
            case(state)
                IDLE: begin
                    ready_o <= 1'b1;
                    valid_o <= 1'b0;
                    if (valid_i && ready_o) begin
                        multiplicand <= {4'b0000, x};
                        multiplier <= {4'b0000, y};
                        counter <= 4'b0000;
                        product <= 8'h00;
                        next_state <= CALC;
                        ready_o <= 1'b0;
                    end
                end
                CALC: begin
                    if (counter < 8) begin
                        if (multiplier[0] == 1'b1) begin
                            product <= product + multiplicand;
                        end
                        multiplicand <= multiplicand << 1;
                        multiplier <= multiplier >> 1;
                        counter <= counter + 1;
                    end else begin
                        case({x, y})
                            8'h00: result <= 8'hFF;
                            8'h01: result <= 8'h00;
                            default: result <= product;
                        endcase
                        valid_o <= 1'b1;
                        if (ready_i) begin
                            q <= result;
                            valid_o <= 1'b0;
                            next_state <= IDLE;
                        end
                    end
                end
            endcase
        end
    end
endmodule