//SystemVerilog
// Top-level module
module bcd2bin #(parameter N=4) (
    input [N*4-1:0] bcd,
    output [N*7-1:0] bin
);
    // Internal connections
    wire [3:0] bcd_digits [N-1:0];
    wire [6:0] bin_values [N-1:0];
    
    // Split BCD input into individual digits
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : bcd_split
            assign bcd_digits[i] = bcd[i*4+:4];
        end
    endgenerate
    
    // Convert each BCD digit to its weighted binary value
    generate
        for (i = 0; i < N; i = i + 1) begin : digit_converters
            bcd_digit_converter #(.WEIGHT(i)) converter_inst (
                .bcd_digit(bcd_digits[i]),
                .weighted_value(bin_values[i])
            );
        end
    endgenerate
    
    // Combine weighted binary values into output
    generate
        for (i = 0; i < N; i = i + 1) begin : bin_combine
            assign bin[i*7+:7] = bin_values[i];
        end
    endgenerate
endmodule

// Submodule for converting a single BCD digit to its weighted binary value
module bcd_digit_converter #(parameter WEIGHT=0) (
    input [3:0] bcd_digit,
    output [6:0] weighted_value
);
    // Compute weight factor (10^WEIGHT)
    localparam [6:0] WEIGHT_FACTOR = weight_calc(WEIGHT);
    
    // Calculate weighted binary value
    assign weighted_value = bcd_digit * WEIGHT_FACTOR;
    
    // Function to calculate weight (10^WEIGHT)
    function [6:0] weight_calc;
        input integer w;
        integer i;
        begin
            weight_calc = 1;
            for (i = 0; i < w; i = i + 1)
                weight_calc = weight_calc * 10;
        end
    endfunction
endmodule