module pll_clock_gen(
    input refclk,
    input reset,
    input [3:0] mult_factor,
    input [3:0] div_factor,
    output reg outclk
);
    reg [3:0] mult_count, div_count;
    
    always @(posedge refclk or posedge reset) begin
        if (reset) begin
            mult_count <= 4'd0;
            outclk <= 1'b0;
        end else if (mult_count >= mult_factor - 1) begin
            mult_count <= 4'd0;
            outclk <= ~outclk;
        end else
            mult_count <= mult_count + 1'b1;
    end
endmodule