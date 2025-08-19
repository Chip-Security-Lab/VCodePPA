module subtractor_signed_4bit (
    input wire clk,
    input wire rst_n,
    input signed [3:0] a,
    input signed [3:0] b,
    output reg signed [3:0] diff
);

    // Pipeline stage 1: Input register and subtraction
    reg signed [3:0] a_reg;
    reg signed [3:0] b_reg;
    reg signed [3:0] diff_reg;

    // Input pipeline stage and subtraction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
            diff_reg <= 4'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            diff_reg <= a - b;
        end
    end

    // Output pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff <= 4'b0;
        end else begin
            diff <= diff_reg;
        end
    end

endmodule