module async_buffer (
    input wire [15:0] data_in,
    input wire enable,
    output wire [15:0] data_out
);
    assign data_out = enable ? data_in : 16'b0;
endmodule