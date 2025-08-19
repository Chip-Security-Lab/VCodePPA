module async_arbiter #(parameter WIDTH=4) (
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
reg [WIDTH-1:0] mask;
always @* begin
    mask = req_i & (~req_i + 1);
    grant_o = mask & req_i;
end
endmodule