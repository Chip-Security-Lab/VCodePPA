module binary_to_onehot_sync #(parameter ADDR_WIDTH = 4) (
    input                       clk,
    input                       rst_n,
    input                       enable,
    input      [ADDR_WIDTH-1:0] binary_in,
    output reg [2**ADDR_WIDTH-1:0] onehot_out
);
    always @(posedge clk) begin
        if (!rst_n)
            onehot_out <= {(2**ADDR_WIDTH){1'b0}};
        else if (enable)
            onehot_out <= {{(2**ADDR_WIDTH-1){1'b0}}, 1'b1} << binary_in;
    end
endmodule