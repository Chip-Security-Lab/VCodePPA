module async_reset_fanout(
    input wire async_rst_in,
    output wire [15:0] rst_out
);
    assign rst_out = {16{async_rst_in}};  // Distribute reset to all outputs
endmodule