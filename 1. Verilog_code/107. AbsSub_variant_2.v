module AbsSub(
    input wire clk,
    input wire rst_n,
    input wire signed [7:0] x,
    input wire signed [7:0] y,
    output reg signed [7:0] res
);

    // Pipeline registers
    reg signed [7:0] x_reg;
    reg signed [7:0] y_reg;
    reg comp_result;
    reg signed [7:0] sum_reg;
    reg signed [7:0] diff_reg;
    
    // Stage 1: Register inputs and compute comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_reg <= 8'd0;
            y_reg <= 8'd0;
            comp_result <= 1'b0;
            sum_reg <= 8'd0;
            diff_reg <= 8'd0;
        end else begin
            x_reg <= x;
            y_reg <= y;
            comp_result <= (x > y);
            sum_reg <= x + y;
            diff_reg <= x - y;
        end
    end

    // Stage 2: Compute absolute difference using conditional sum
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            res <= 8'd0;
        end else begin
            res <= comp_result ? diff_reg : (~diff_reg + 1'b1);
        end
    end

endmodule