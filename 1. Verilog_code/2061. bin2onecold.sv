module bin2onecold #(parameter BIN_WIDTH = 3) (
    input wire [BIN_WIDTH-1:0] bin_in,
    output wire [(2**BIN_WIDTH)-1:0] onecold_out
);
    assign onecold_out = ~(1'b1 << bin_in);
endmodule