module dual_reset_matcher #(parameter W = 8) (
    input clk, sync_rst, async_rst_n,
    input [W-1:0] data, template,
    input qualify,
    output reg valid_match
);
    reg match_r;
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            match_r <= 1'b0;
        else if (sync_rst)
            match_r <= 1'b0;
        else
            match_r <= (data == template);
    end
    
    always @(posedge clk or negedge async_rst_n)
        if (!async_rst_n)
            valid_match <= 1'b0;
        else if (sync_rst)
            valid_match <= 1'b0;
        else
            valid_match <= match_r & qualify;
endmodule