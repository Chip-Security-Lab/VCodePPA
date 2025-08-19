module clk_gate_sync #(parameter WIDTH=4) (
    input clk, en,
    output reg [WIDTH-1:0] out
);
always @(posedge clk) begin
    out <= en ? out + 1 : out;
end
endmodule