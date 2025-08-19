module decoder_pipelined (
    input clk, en,
    input [5:0] addr,
    output reg [15:0] sel_reg
);
reg [15:0] sel_comb;
always @* begin
    sel_comb = (en) ? (1 << addr) : 16'b0;
end
always @(posedge clk) begin
    sel_reg <= sel_comb;
end
endmodule