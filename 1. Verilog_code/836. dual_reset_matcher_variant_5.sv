//SystemVerilog
module dual_reset_matcher #(parameter W = 8) (
    input clk, sync_rst, async_rst_n,
    input [W-1:0] data, template,
    input qualify,
    output reg valid_match
);
    // Lookup table for difference calculation
    reg [W-1:0] diff_lut [0:255];
    reg [W-1:0] diff_result;
    reg match_r;
    
    // Initialize lookup table
    initial begin
        integer i, j;
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                diff_lut[i] = i - j;
            end
        end
    end
    
    // Calculate difference using lookup table
    always @(*) begin
        diff_result = diff_lut[data] - diff_lut[template];
    end
    
    // Match detection using lookup table result
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            match_r <= 1'b0;
        else if (sync_rst)
            match_r <= 1'b0;
        else
            match_r <= (diff_result == 0);
    end
    
    // Output generation
    always @(posedge clk or negedge async_rst_n)
        if (!async_rst_n)
            valid_match <= 1'b0;
        else if (sync_rst)
            valid_match <= 1'b0;
        else
            valid_match <= match_r & qualify;
endmodule