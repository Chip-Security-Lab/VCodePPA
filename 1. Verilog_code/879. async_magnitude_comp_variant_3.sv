//SystemVerilog
module async_magnitude_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] a, b,
    output [WIDTH-1:0] diff_magnitude,
    output [$clog2(WIDTH)-1:0] priority_bit,
    output a_larger
);
    wire [WIDTH-1:0] difference;
    wire [WIDTH-1:0] abs_diff;
    wire [WIDTH-1:0] bit_vector;
    wire [$clog2(WIDTH)-1:0] msb_index;

    assign a_larger = a > b;

    // Use a multiplexer for conditional assignment
    assign abs_diff = a_larger ? a - b : b - a;

    assign diff_magnitude = abs_diff;

    // Optimized priority encoder using a case statement structure
    // This structure can be optimized by synthesis tools
    assign bit_vector = abs_diff;

    genvar i;
    generate
        if (WIDTH == 1) begin : msb_gen_1
            assign msb_index = 0;
        end else begin : msb_gen
            assign msb_index = 0; // Default value
            for (i = 0; i < WIDTH; i = i + 1) begin : msb_check
                if (i == WIDTH - 1) begin
                    assign msb_index = bit_vector[i] ? i : msb_index;
                end else begin
                    assign msb_index = bit_vector[i] && !(|bit_vector[WIDTH-1:i+1]) ? i : msb_index;
                end
            end
        end
    endgenerate

    assign priority_bit = msb_index;

endmodule