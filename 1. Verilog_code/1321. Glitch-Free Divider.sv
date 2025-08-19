module glitch_free_divider (
    input wire clk_i, rst_i,
    output wire clk_o
);
    reg [2:0] count_r;
    reg clk_pos, clk_neg;
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            count_r <= 3'd0;
            clk_pos <= 1'b0;
        end else if (count_r == 3'd3) begin
            count_r <= 3'd0;
            clk_pos <= ~clk_pos;
        end else
            count_r <= count_r + 1'b1;
    end
    
    always @(negedge clk_i) begin
        if (rst_i)
            clk_neg <= 1'b0;
        else
            clk_neg <= clk_pos;
    end
    
    assign clk_o = clk_neg;
endmodule