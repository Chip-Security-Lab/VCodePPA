module AsymCompress #(IN_W=64, OUT_W=32) (
    input [IN_W-1:0] din,
    output [OUT_W-1:0] dout
);
reg [OUT_W-1:0] result;
integer i;

always @(*) begin
    result = 0;
    for(i=0; i<IN_W/OUT_W; i=i+1) begin
        result = result ^ din[i*OUT_W +: OUT_W];
    end
end

assign dout = result;
endmodule