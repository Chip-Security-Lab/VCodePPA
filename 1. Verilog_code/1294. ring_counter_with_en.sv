module ring_counter_with_en (
    input clk, en, rst,
    output reg [3:0] q
);
always @(posedge clk) begin
    if (rst) q <= 4'b0001;
    else if (en) q <= {q[0], q[3:1]};
end
endmodule
