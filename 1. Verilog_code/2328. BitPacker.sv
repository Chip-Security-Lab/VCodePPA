module BitPacker #(IN_W=32, OUT_W=64, EFF_BITS=8) (
    input clk, ce,
    input [IN_W-1:0] din,
    output reg [OUT_W-1:0] dout,
    output reg valid
);
reg [OUT_W-1:0] buffer = 0;
reg [5:0] bit_ptr = 0;
always @(posedge clk) if(ce) begin
    buffer <= buffer | (din[EFF_BITS-1:0] << bit_ptr);
    bit_ptr <= bit_ptr + EFF_BITS;
    valid <= (bit_ptr + EFF_BITS) >= OUT_W;
    dout <= valid ? buffer : 0;
end
endmodule
