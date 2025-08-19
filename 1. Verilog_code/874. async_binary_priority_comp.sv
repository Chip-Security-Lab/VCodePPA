module async_binary_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_vector,
    output [$clog2(WIDTH)-1:0] encoded_output,
    output valid_output
);
    // Combinational logic for binary encoding
    reg [$clog2(WIDTH)-1:0] encoder_out;
    integer idx;
    
    always @(*) begin
        encoder_out = 0;
        for (idx = 0; idx < WIDTH; idx = idx + 1)
            if (data_vector[idx]) encoder_out = idx[$clog2(WIDTH)-1:0];
    end
    
    assign encoded_output = encoder_out;
    assign valid_output = |data_vector;
endmodule