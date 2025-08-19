module clk_gate_mask #(parameter MASK=4'b1100) (
    input clk, en,
    output reg [3:0] out
);
always @(posedge clk) begin
    out <= en ? (out | MASK) : out;
end
endmodule