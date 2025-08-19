module param_decoder #(
    parameter ADDR_WIDTH = 3,
    parameter OUT_WIDTH = 2**ADDR_WIDTH
)(
    input [ADDR_WIDTH-1:0] addr_bus,
    output reg [OUT_WIDTH-1:0] decoded
);
    integer i;
    always @(*) begin
        for (i = 0; i < OUT_WIDTH; i = i + 1)
            decoded[i] = (i == addr_bus) ? 1'b1 : 1'b0;
    end
endmodule