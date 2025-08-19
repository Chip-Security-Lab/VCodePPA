module gen_ring_counter #(parameter WIDTH=8) (
    input clk, rst,
    output reg [WIDTH-1:0] cnt
);
generate
    always @(posedge clk) begin
        if (rst) cnt <= {{WIDTH-1{1'b0}}, 1'b1};
        else cnt <= {cnt[0], cnt[WIDTH-1:1]};
    end
endgenerate
endmodule
