//SystemVerilog
module param_clock_divider #(
    parameter DIVISOR = 4,
    parameter WIDTH = (DIVISOR > 1) ? $clog2(DIVISOR) : 1
)(
    input wire clk_in,
    input wire rst_n,
    output reg clk_out
);
    reg [WIDTH-1:0] counter;

    wire counter_max = (counter >= (DIVISOR - 1));

    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {WIDTH{1'b0}};
            clk_out <= 1'b0;
        end else if (counter_max) begin
            counter <= {WIDTH{1'b0}};
            clk_out <= ~clk_out;
        end else begin
            counter <= counter + 1'b1;
        end
    end
endmodule