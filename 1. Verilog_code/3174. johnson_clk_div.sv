module johnson_clk_div(
    input clk_i,
    input rst_i,
    output [3:0] clk_o
);
    reg [3:0] johnson_cnt;
    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            johnson_cnt <= 4'b0000;
        else
            johnson_cnt <= {~johnson_cnt[0], johnson_cnt[3:1]};
    end
    
    assign clk_o = johnson_cnt;
endmodule