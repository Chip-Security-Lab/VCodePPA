module HuffmanStaticEnc #(SYM_W=4, CODE_W=8) (
    input clk, en,
    input [SYM_W-1:0] symbol,
    output reg [CODE_W-1:0] code
);
reg [CODE_W-1:0] lut [0:(1<<SYM_W)-1];
initial $readmemb("huffman_table.mem", lut);
always @(posedge clk) if(en) code <= lut[symbol];
endmodule
