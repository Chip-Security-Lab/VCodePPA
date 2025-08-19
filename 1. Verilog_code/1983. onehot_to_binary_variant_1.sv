//SystemVerilog
module onehot_to_binary #(parameter ONE_HOT_WIDTH=8)(
    input wire [ONE_HOT_WIDTH-1:0] onehot_in,
    output reg [$clog2(ONE_HOT_WIDTH)-1:0] binary_out
);
    integer idx;
    always @* begin
        binary_out = {$clog2(ONE_HOT_WIDTH){1'b0}};
        if (ONE_HOT_WIDTH == 1) begin
            binary_out = 0;
        end else begin
            for (idx = ONE_HOT_WIDTH-1; idx >= 0; idx = idx - 1) begin
                if (onehot_in[idx]) begin
                    binary_out = idx[$clog2(ONE_HOT_WIDTH)-1:0];
                end
            end
        end
    end
endmodule