module decoder_gated #(WIDTH=3) (
    input clk, clk_en,
    input [WIDTH-1:0] addr,
    output reg [7:0] decoded
);
always @(posedge clk) begin
    if(clk_en) decoded <= 1 << addr;
    else decoded <= decoded;  // 保持当前状态
end
endmodule