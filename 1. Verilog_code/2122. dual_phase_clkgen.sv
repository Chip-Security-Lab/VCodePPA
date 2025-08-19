module dual_phase_clkgen(
    input sys_clk,
    input async_rst,
    output reg clk_0deg,
    output reg clk_180deg
);
    always @(posedge sys_clk or posedge async_rst) begin
        if (async_rst) begin
            clk_0deg <= 1'b0;
            clk_180deg <= 1'b1;
        end else begin
            clk_0deg <= clk_180deg;
            clk_180deg <= clk_0deg;
        end
    end
endmodule