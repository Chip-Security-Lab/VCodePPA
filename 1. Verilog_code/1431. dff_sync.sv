module dff_sync #(parameter WIDTH=1) (
    input clk, rstn, 
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
always @(posedge clk) begin
    if (!rstn) q <= 0;
    else       q <= d;
end
endmodule