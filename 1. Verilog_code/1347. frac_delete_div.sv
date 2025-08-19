module frac_delete_div #(parameter ACC_WIDTH=8) (
    input clk, rst,
    output reg clk_out
);
reg [ACC_WIDTH-1:0] acc;
always @(posedge clk) begin
    if(rst) begin
        acc <= 0;
        clk_out <= 0;
    end else begin
        acc <= acc + 3;  // 示例分数 (3/8)*2 = 0.75
        clk_out <= (acc < 8'h80) ? 1'b1 : 1'b0;
    end
end
endmodule
