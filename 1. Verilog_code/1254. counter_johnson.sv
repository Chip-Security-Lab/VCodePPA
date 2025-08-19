module counter_johnson #(parameter STAGES=4) (
    input clk, rst,
    output reg [STAGES-1:0] j_reg
);
always @(posedge clk) begin
    if (rst) j_reg <= 0;
    else j_reg <= {~j_reg[0], j_reg[STAGES-1:1]};
end
endmodule
