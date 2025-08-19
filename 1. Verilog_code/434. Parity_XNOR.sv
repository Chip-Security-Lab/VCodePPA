module Parity_XNOR(
    input [7:0] data,
    output parity
);
    assign parity = ~^data; // 奇偶校验同或
endmodule
