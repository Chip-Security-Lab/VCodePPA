module ring_counter_param #(parameter WIDTH=4) (
    input clk, rst,
    output reg [WIDTH-1:0] counter_reg
);
always @(posedge clk) begin
    if (rst) counter_reg <= {{WIDTH-1{1'b0}}, 1'b1};
    else counter_reg <= {counter_reg[0], counter_reg[WIDTH-1:1]};
end
endmodule
