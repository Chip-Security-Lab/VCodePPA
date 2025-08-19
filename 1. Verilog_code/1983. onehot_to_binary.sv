module onehot_to_binary #(parameter ONE_HOT_WIDTH=8)(
    input wire [ONE_HOT_WIDTH-1:0] onehot_in,
    output reg [$clog2(ONE_HOT_WIDTH)-1:0] binary_out
);
    integer i;
    always @* begin
        binary_out = 0;
        for (i = 0; i < ONE_HOT_WIDTH; i = i + 1) begin
            if (onehot_in[i]) binary_out = i[$clog2(ONE_HOT_WIDTH)-1:0];
        end
    end
endmodule