module ShiftLeft #(parameter WIDTH=8) (
    input clk, rst_n, en, serial_in,
    output reg [WIDTH-1:0] q
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) q <= 0;
    else if (en) q <= {q[WIDTH-2:0], serial_in};
end
endmodule
