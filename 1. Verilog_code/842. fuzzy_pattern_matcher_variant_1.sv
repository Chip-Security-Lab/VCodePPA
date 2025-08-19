//SystemVerilog
module fuzzy_pattern_matcher #(parameter W = 8, MAX_MISMATCHES = 2) (
    input clk,
    input rst_n,
    input [W-1:0] data,
    input [W-1:0] pattern,
    output reg match
);

    // Stage 1: Pattern Comparison
    reg [W-1:0] diff_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            diff_reg <= '0;
        else
            diff_reg <= data ^ pattern;
    end

    // Stage 2: Mismatch Counting
    reg [$clog2(W):0] mismatch_count_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mismatch_count_reg <= '0;
        else begin
            mismatch_count_reg <= '0;
            for (int i = 0; i < W; i = i + 1)
                if (diff_reg[i])
                    mismatch_count_reg <= mismatch_count_reg + 1;
        end
    end

    // Stage 3: Match Decision
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            match <= 1'b0;
        else
            match <= (mismatch_count_reg <= MAX_MISMATCHES);
    end

endmodule