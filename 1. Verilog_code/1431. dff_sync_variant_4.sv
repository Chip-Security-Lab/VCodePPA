//SystemVerilog
module dff_sync #(parameter WIDTH=1) (
    input wire clk, rstn, 
    input wire [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);

always @(posedge clk) begin
    if (!rstn) 
        q <= {WIDTH{1'b0}};
    else
        q <= d;
end
endmodule