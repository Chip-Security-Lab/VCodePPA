module block_fp #(
    parameter N = 4,
    parameter W = 16
)(
    input [W-1:0] in_array [0:N-1],  // Fixed array declaration
    output [W+3:0] out_array [0:N-1],
    output [3:0] exp
);
    // Improved max exponent logic
    reg [3:0] max_exp;
    integer i;
    
    // Improved function for log2 calculation
    function [3:0] log2_func;
        input [W-1:0] value;
        integer j;
        reg found;
        begin
            log2_func = 0;
            found = 0;
            
            for (j = W-1; j >= 0; j = j - 1) begin
                if (value[j] && !found) begin
                    log2_func = j;
                    found = 1;
                end
            end
        end
    endfunction
    
    always @(*) begin
        max_exp = log2_func(in_array[0]);
        
        for (i = 1; i < N; i = i + 1) begin
            if (log2_func(in_array[i]) > max_exp)
                max_exp = log2_func(in_array[i]);
        end
    end
    
    assign exp = max_exp;
    
    // Generate output logic
    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : gen_output
            assign out_array[g] = in_array[g] << (max_exp - log2_func(in_array[g]));
        end
    endgenerate
endmodule