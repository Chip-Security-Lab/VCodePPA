module cascadable_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_in,
    input cascade_in_valid,
    input [$clog2(WIDTH)-1:0] cascade_in_idx,
    output cascade_out_valid,
    output [$clog2(WIDTH)-1:0] cascade_out_idx
);
    wire local_valid;
    wire [$clog2(WIDTH)-1:0] local_idx;
    
    // Local priority encoder
    assign local_valid = |data_in;
    
    function [$clog2(WIDTH)-1:0] encode_priority;
        input [WIDTH-1:0] data;
        integer i;
        begin
            encode_priority = 0;
            for (i = WIDTH-1; i >= 0; i = i - 1)
                if (data[i]) encode_priority = i[$clog2(WIDTH)-1:0];
        end
    endfunction
    
    assign local_idx = encode_priority(data_in);
    
    // Cascade logic
    assign cascade_out_valid = local_valid || cascade_in_valid;
    assign cascade_out_idx = local_valid ? local_idx : cascade_in_idx;
endmodule