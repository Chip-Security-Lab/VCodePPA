//SystemVerilog
module param_decoder #(
    parameter ADDR_WIDTH = 3,
    parameter OUT_WIDTH = 2**ADDR_WIDTH
)(
    input [ADDR_WIDTH-1:0] addr_bus,
    output reg [OUT_WIDTH-1:0] decoded
);

    always @(*) begin
        decoded = {OUT_WIDTH{1'b0}};
        decoded[addr_bus] = 1'b1;
    end

endmodule