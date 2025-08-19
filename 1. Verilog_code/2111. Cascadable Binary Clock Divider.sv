module binary_clk_divider(
    input clk_i,
    input rst_i,
    output [3:0] clk_div  // 2^1, 2^2, 2^3, 2^4 division
);
    reg [3:0] div_reg;
    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            div_reg <= 4'b0000;
        else
            div_reg <= div_reg + 4'b0001;
    end
    
    assign clk_div = div_reg;
endmodule