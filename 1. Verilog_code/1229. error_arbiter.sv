module error_arbiter #(WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    input error_en,
    output reg [WIDTH-1:0] grant_o
);
wire [WIDTH-1:0] normal_grant = req_i & (~req_i + 1);
always @(posedge clk) begin
    grant_o <= error_en ? {WIDTH{1'b1}} : normal_grant;
end
endmodule
