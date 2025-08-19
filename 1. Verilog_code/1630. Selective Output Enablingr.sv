module selective_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter OUT_WIDTH = 16,
    parameter ENABLE_MASK = 16'hFFFF
)(
    input [ADDR_WIDTH-1:0] addr,
    input enable,
    output [OUT_WIDTH-1:0] select
);
    wire [OUT_WIDTH-1:0] full_decode;
    
    assign full_decode = enable ? (1 << addr) : {OUT_WIDTH{1'b0}};
    assign select = full_decode & ENABLE_MASK;
endmodule