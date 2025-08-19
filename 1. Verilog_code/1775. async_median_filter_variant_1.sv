//SystemVerilog
module async_median_filter #(
    parameter W = 16
)(
    input  clk,
    input  rst_n,
    input  [W-1:0] a, b, c,
    output reg [W-1:0] med_out
);

    // Stage 1: Compare a and b
    reg [W-1:0] min_ab, max_ab;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            min_ab <= {W{1'b0}};
            max_ab <= {W{1'b0}};
        end else begin
            min_ab <= (a < b) ? a : b;
            max_ab <= (a > b) ? a : b;
        end
    end

    // Stage 2: Compare with c
    reg [W-1:0] stage2_result;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= {W{1'b0}};
        end else begin
            if (c < min_ab)
                stage2_result <= min_ab;
            else if (c > max_ab)
                stage2_result <= max_ab;
            else
                stage2_result <= c;
        end
    end

    // Stage 3: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            med_out <= {W{1'b0}};
        end else begin
            med_out <= stage2_result;
        end
    end

endmodule