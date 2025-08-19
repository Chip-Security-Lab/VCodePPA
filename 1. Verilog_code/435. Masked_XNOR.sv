module Masked_XNOR(
    input en_mask,
    input [3:0] mask, data,
    output [3:0] res
);
    assign res = en_mask ? ~(data ^ mask) : data;
endmodule
