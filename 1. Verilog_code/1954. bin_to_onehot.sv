module bin_to_onehot #(
    parameter BIN_WIDTH = 4
)(
    input wire [BIN_WIDTH-1:0] bin_in,
    input wire enable,
    output reg [(1<<BIN_WIDTH)-1:0] onehot_out
);
    always @(*) begin
        onehot_out = enable ? (1'b1 << bin_in) : 0;
    end
endmodule