//SystemVerilog
module agc_unit #(parameter W = 16) (
    input wire clk,
    input wire [W-1:0] in,
    output reg [W-1:0] out
);

    // Stage 1: Peak calculation
    reg [W+1:0] peak_reg = 0;
    reg [W+1:0] peak_adj_comb;
    reg [W+1:0] peak_next_comb;
    reg [W+1:0] peak_adj_reg;
    reg [W+1:0] peak_next_reg;

    // Stage 2: Divisor calculation and multiplication
    reg [W+1:0] divisor_comb;
    reg [W+1:0] divisor_reg;
    reg [W+15:0] mult_result_comb;
    reg [W+15:0] mult_result_reg;
    reg [W-1:0] in_reg;

    // Stage 3: Division and output
    reg [W-1:0] norm_factor_comb;

    // Pipeline Stage 1: Compute peak_adj and peak_next
    always @* begin
        peak_adj_comb = peak_reg - (peak_reg >> 3);
        if (in > peak_reg)
            peak_next_comb = in;
        else
            peak_next_comb = peak_adj_comb;
    end

    always @(posedge clk) begin
        peak_adj_reg  <= peak_adj_comb;
        peak_next_reg <= peak_next_comb;
        in_reg        <= in;
    end

    // Pipeline Stage 2: Compute divisor and multiplication
    always @* begin
        if (peak_next_reg != 0)
            divisor_comb = peak_next_reg;
        else
            divisor_comb = 1;
        mult_result_comb = in_reg * 16'd32767;
    end

    always @(posedge clk) begin
        divisor_reg      <= divisor_comb;
        mult_result_reg  <= mult_result_comb;
    end

    // Pipeline Stage 3: Division and output
    always @* begin
        norm_factor_comb = mult_result_reg / divisor_reg;
    end

    always @(posedge clk) begin
        peak_reg <= peak_next_reg;
        out      <= norm_factor_comb;
    end

endmodule