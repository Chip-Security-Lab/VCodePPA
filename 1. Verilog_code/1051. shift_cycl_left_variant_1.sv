//SystemVerilog
module shift_cycl_left #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) data_out <= 0;
    else if (en) data_out <= {data_in[WIDTH-2:0], data_in[WIDTH-1]};
end
endmodule
