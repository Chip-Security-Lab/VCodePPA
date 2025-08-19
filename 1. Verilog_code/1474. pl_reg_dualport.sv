module pl_reg_dualport #(parameter W=16) (
    input clk, wr1_en, wr2_en,
    input [W-1:0] wr1_data, wr2_data,
    output reg [W-1:0] q
);
always @(posedge clk) begin
    casex({wr1_en, wr2_en})
        2'b1x: q <= wr1_data;
        2'b01: q <= wr2_data;
    endcase
end
endmodule