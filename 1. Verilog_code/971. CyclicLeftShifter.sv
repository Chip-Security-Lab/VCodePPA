module CyclicLeftShifter #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input serial_in,
    output reg [WIDTH-1:0] parallel_out
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) parallel_out <= 0;
    else if (en) parallel_out <= {parallel_out[WIDTH-2:0], serial_in};
end
endmodule