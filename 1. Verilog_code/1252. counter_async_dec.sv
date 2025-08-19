module counter_async_dec #(parameter WIDTH=4) (
    input clk, rst, en,
    output reg [WIDTH-1:0] count
);
always @(posedge clk, posedge rst) begin
    if (rst) count <= {WIDTH{1'b1}};
    else if (en) count <= count - 1;
end
endmodule