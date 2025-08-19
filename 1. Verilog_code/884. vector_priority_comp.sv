module vector_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_vector,
    input [WIDTH-1:0] priority_mask,
    output [$clog2(WIDTH)-1:0] encoded_position,
    output valid_output
);
    wire [WIDTH-1:0] masked_data;
    assign masked_data = data_vector & priority_mask;
    
    // Priority encoder logic
    function [$clog2(WIDTH)-1:0] encode_priority;
        input [WIDTH-1:0] data;
        integer i;
        begin
            encode_priority = 0;
            for (i = WIDTH-1; i >= 0; i = i - 1)
                if (data[i]) encode_priority = i[$clog2(WIDTH)-1:0];
        end
    endfunction
    
    assign encoded_position = encode_priority(masked_data);
    assign valid_output = |masked_data;
endmodule