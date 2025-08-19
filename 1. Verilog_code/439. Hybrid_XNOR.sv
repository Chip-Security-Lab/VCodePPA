module Hybrid_XNOR(
    input [1:0] ctrl,
    input [7:0] base,
    output [7:0] res
);
    assign res = ~(base ^ (8'h0F << (ctrl * 2)));
endmodule
