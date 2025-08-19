module onehot_to_binary_priority #(parameter OH_WIDTH = 8) (
    input  wire [OH_WIDTH-1:0] onehot_input,
    output reg  [$clog2(OH_WIDTH)-1:0] binary_output,
    output wire valid
);
    integer j;
    assign valid = |onehot_input;
    
    always @(*) begin
        binary_output = {$clog2(OH_WIDTH){1'b0}};
        for (j = 0; j < OH_WIDTH; j = j + 1)
            if (onehot_input[j])
                binary_output = j[$clog2(OH_WIDTH)-1:0];
    end
endmodule