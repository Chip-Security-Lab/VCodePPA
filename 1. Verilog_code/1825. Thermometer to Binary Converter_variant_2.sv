//SystemVerilog
module therm2bin_converter #(parameter THERM_WIDTH = 7) (
    input  wire [THERM_WIDTH-1:0] therm_code,
    output wire [$clog2(THERM_WIDTH+1)-1:0] bin_code
);

    // Use parallel prefix adder for efficient counting
    wire [THERM_WIDTH-1:0] sum_bits;
    wire [$clog2(THERM_WIDTH+1)-1:0] final_sum;
    
    // First level: count pairs
    genvar i;
    generate
        for (i = 0; i < THERM_WIDTH/2; i = i + 1) begin : PAIR_COUNT
            assign sum_bits[i] = therm_code[2*i] + therm_code[2*i+1];
        end
        if (THERM_WIDTH % 2) begin
            assign sum_bits[THERM_WIDTH/2] = therm_code[THERM_WIDTH-1];
        end
    endgenerate
    
    // Second level: accumulate results
    assign final_sum = sum_bits[THERM_WIDTH-1:0];
    
    assign bin_code = final_sum;
endmodule