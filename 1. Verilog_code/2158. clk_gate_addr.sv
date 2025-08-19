module clk_gate_addr #(parameter AW=2) (
    input clk, en,
    input [AW-1:0] addr,
    output reg [2**AW-1:0] decode
);
always @(posedge clk) begin
    decode <= en ? (1'b1 << addr) : {2**AW{1'b0}};
end
endmodule