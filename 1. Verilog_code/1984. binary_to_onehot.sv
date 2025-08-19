module binary_to_onehot #(parameter BINARY_WIDTH=3)(
    input wire [BINARY_WIDTH-1:0] binary_in,
    output reg [2**BINARY_WIDTH-1:0] onehot_out
);
    always @* begin
        onehot_out = 1'b1 << binary_in;
    end
endmodule