//SystemVerilog
// SystemVerilog
// Submodule for magnitude calculation
module magnitude_calc #(parameter WIDTH = 8)(
    input [WIDTH-1:0] a, b,
    output [WIDTH-1:0] diff_magnitude,
    output a_larger
);
    assign a_larger = a > b;
    assign diff_magnitude = a_larger ? a - b : b - a;
endmodule

// Submodule for priority encoding
module priority_encoder #(parameter WIDTH = 8)(
    input [WIDTH-1:0] value,
    output [$clog2(WIDTH)-1:0] priority_bit
);
    // Priority encoder for most significant 1
    function [$clog2(WIDTH)-1:0] find_msb;
        input [WIDTH-1:0] input_value;
        integer i;
        begin
            find_msb = 0;
            for (i = WIDTH-1; i >= 0; i = i - 1)
                if (input_value[i]) begin
                    find_msb = i[$clog2(WIDTH)-1:0];
                    // Optimization: break after finding the first '1' from MSB
                    // This can improve synthesis results for some tools
                    // break; // SystemVerilog 'break' is not standard Verilog
                    // Using a flag or structured logic instead
                    if (input_value[i]) begin
                        find_msb = i[$clog2(WIDTH)-1:0];
                        // No break in pure Verilog, rely on synthesis tool optimization
                    end
                end
        end
    endfunction
    
    assign priority_bit = find_msb(value);
endmodule

// Top-level module combining magnitude calculation and priority encoding
module async_magnitude_comp_hier #(parameter WIDTH = 8)(
    input [WIDTH-1:0] a, b,
    output [WIDTH-1:0] diff_magnitude,
    output [$clog2(WIDTH)-1:0] priority_bit,
    output a_larger
);
    wire [WIDTH-1:0] magnitude_diff_w;
    wire a_is_larger_w;

    // Instantiate magnitude calculation submodule
    magnitude_calc #(
        .WIDTH(WIDTH)
    ) u_magnitude_calc (
        .a(a),
        .b(b),
        .diff_magnitude(magnitude_diff_w),
        .a_larger(a_is_larger_w)
    );

    // Instantiate priority encoder submodule
    priority_encoder #(
        .WIDTH(WIDTH)
    ) u_priority_encoder (
        .value(magnitude_diff_w),
        .priority_bit(priority_bit)
    );

    // Assign outputs from submodules
    assign diff_magnitude = magnitude_diff_w;
    assign a_larger = a_is_larger_w;

endmodule