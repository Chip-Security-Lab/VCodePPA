module ITRC_SoftAck #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,
    input [WIDTH-1:0] ack_mask,
    output reg [WIDTH-1:0] pending
);
    always @(posedge clk) begin
        if (!rst_n) pending <= 0;
        else pending <= (pending | int_src) & ~ack_mask;
    end
endmodule