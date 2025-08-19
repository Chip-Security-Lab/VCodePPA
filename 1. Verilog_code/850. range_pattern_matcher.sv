module range_pattern_matcher #(parameter WIDTH = 8) (
    input clk, rst_n,
    input [WIDTH-1:0] data, lower_bound, upper_bound,
    output reg in_range
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            in_range <= 1'b0;
        else
            in_range <= (data >= lower_bound) && (data <= upper_bound);
    end
endmodule