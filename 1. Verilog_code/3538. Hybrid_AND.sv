module Hybrid_AND(
    input [1:0] ctrl,
    input [7:0] base,
    output [7:0] result
);
    assign result = base & (8'h0F << (ctrl * 4));
endmodule
