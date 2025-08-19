module clk_gate_param #(parameter DW=8, AW=4) (
    input clk, en,
    input [AW-1:0] addr,
    output reg [DW-1:0] data
);
always @(posedge clk) begin
    data <= en ? (addr << 2) : {DW{1'b0}};
end
endmodule