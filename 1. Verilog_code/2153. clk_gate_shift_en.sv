module clk_gate_shift_en #(parameter DEPTH=3) (
    input clk, en, in,
    output reg [DEPTH-1:0] out
);
always @(posedge clk) begin
    if(en) out <= {out[DEPTH-2:0], in};
end
endmodule