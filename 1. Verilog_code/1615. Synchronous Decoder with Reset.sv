module sync_decoder_with_reset #(
    parameter ADDR_BITS = 2,
    parameter OUT_BITS = 4
)(
    input wire clk,
    input wire rst,
    input wire [ADDR_BITS-1:0] addr,
    output reg [OUT_BITS-1:0] decode
);
    always @(posedge clk) begin
        if (rst)
            decode <= 0;
        else
            decode <= (1 << addr);
    end
endmodule