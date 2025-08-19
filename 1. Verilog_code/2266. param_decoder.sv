module param_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter OUT_WIDTH = 16
)(
    input [ADDR_WIDTH-1:0] address,
    input enable,
    output [OUT_WIDTH-1:0] select
);
    wire [OUT_WIDTH-1:0] decode;
    assign decode = (1 << address);
    assign select = enable ? decode : {OUT_WIDTH{1'b0}};
endmodule