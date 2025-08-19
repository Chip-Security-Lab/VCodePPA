module enabled_pattern_compare #(parameter DWIDTH = 16) (
    input clk, rst_n, en,
    input [DWIDTH-1:0] in_data, in_pattern,
    output reg match
);
    always @(posedge clk) begin
        if (!rst_n)
            match <= 1'b0;
        else if (en)
            match <= (in_data == in_pattern);
    end
endmodule