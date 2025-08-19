//SystemVerilog
module onehot_to_binary_priority #(parameter OH_WIDTH = 8) (
    input  wire [OH_WIDTH-1:0] onehot_input,
    output reg  [$clog2(OH_WIDTH)-1:0] binary_output,
    output wire valid
);

    // Valid signal generation
    assign valid = |onehot_input;

    // Priority encoder logic
    always @(*) begin
        binary_output = {$clog2(OH_WIDTH){1'b0}};
        for (int i = OH_WIDTH-1; i >= 0; i--) begin
            if (onehot_input[i]) begin
                binary_output = i[$clog2(OH_WIDTH)-1:0];
            end
        end
    end

endmodule