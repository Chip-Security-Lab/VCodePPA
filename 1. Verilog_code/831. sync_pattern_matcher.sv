module sync_pattern_matcher #(parameter WIDTH = 8) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in, pattern,
    output reg match_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            match_out <= 1'b0;
        else
            match_out <= (data_in == pattern);
    end
endmodule