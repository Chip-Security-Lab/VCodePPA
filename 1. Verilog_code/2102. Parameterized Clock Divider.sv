module param_clock_divider #(
    parameter DIVISOR = 4,
    parameter WIDTH = $clog2(DIVISOR)
)(
    input wire clk_in,
    input wire rst_n,
    output reg clk_out
);
    reg [WIDTH-1:0] counter;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            clk_out <= 0;
        end else if (counter == DIVISOR-1) begin
            counter <= 0;
            clk_out <= ~clk_out;
        end else
            counter <= counter + 1'b1;
    end
endmodule