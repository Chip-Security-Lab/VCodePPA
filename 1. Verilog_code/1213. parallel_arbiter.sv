module parallel_arbiter #(WIDTH=8) (
    input [WIDTH-1:0] req_i,
    output [WIDTH-1:0] grant_o
);
wire [WIDTH*2-1:0] mask = {req_i, {WIDTH{1'b0}}} >> 1;
wire [WIDTH-1:0] pri_mask = req_i & ~mask[WIDTH*2-1:WIDTH];
assign grant_o = pri_mask & (~pri_mask + 1);
endmodule
