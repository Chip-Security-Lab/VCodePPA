//SystemVerilog
module ITRC_SoftAck #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,
    input [WIDTH-1:0] ack_mask,
    output reg [WIDTH-1:0] pending
);

    wire [WIDTH-1:0] next_pending;
    assign next_pending = !rst_n ? {WIDTH{1'b0}} : 
                         (pending & ~ack_mask) | (int_src & ~ack_mask);

    always @(posedge clk) begin
        pending <= next_pending;
    end

endmodule