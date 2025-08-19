module async_magnitude_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] a, b,
    output [WIDTH-1:0] diff_magnitude,
    output [$clog2(WIDTH)-1:0] priority_bit,
    output a_larger
);
    wire [WIDTH-1:0] difference;
    assign difference = a > b ? a - b : b - a;
    assign a_larger = a > b;
    assign diff_magnitude = difference;
    
    // Priority encoder for most significant 1
    function [$clog2(WIDTH)-1:0] find_msb;
        input [WIDTH-1:0] value;
        integer i;
        begin
            find_msb = 0;
            for (i = WIDTH-1; i >= 0; i = i - 1)
                if (value[i]) find_msb = i[$clog2(WIDTH)-1:0];
        end
    endfunction
    
    assign priority_bit = find_msb(difference);
endmodule