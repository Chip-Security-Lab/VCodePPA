//SystemVerilog
module block_fp #(
    parameter N = 4,
    parameter W = 16
)(
    input  [W-1:0] in_array [0:N-1],
    output [W+3:0] out_array [0:N-1],
    output [3:0] exp
);
    // Max exponent register
    reg [3:0] max_exp;
    integer i;

    // Function for log2 calculation
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

    // Conditional sum and subtract for 4-bit
    function [3:0] cond_sum_sub_4bit;
        input [3:0] a, b;
        input is_sub; // 0: sum, 1: sub
        reg [3:0] p, g, c, s;
        integer k;
        begin
            // Propagate and generate
            for (k = 0; k < 4; k = k + 1) begin
                if (is_sub)
                    p[k] = a[k] ^ ~b[k];
                else
                    p[k] = a[k] ^ b[k];
                if (is_sub)
                    g[k] = a[k] & ~b[k];
                else
                    g[k] = a[k] & b[k];
            end
            // Carry chain
            c[0] = is_sub; // For subtraction, start with carry-in 1 (2's complement)
            for (k = 1; k < 4; k = k + 1) begin
                c[k] = g[k-1] | (p[k-1] & c[k-1]);
            end
            // Sum
            for (k = 0; k < 4; k = k + 1) begin
                s[k] = p[k] ^ c[k];
            end
            cond_sum_sub_4bit = s;
        end
    endfunction

    // Subtraction using conditional sum (for shift amount)
    function [3:0] cond_sub;
        input [3:0] a, b;
        begin
            cond_sub = cond_sum_sub_4bit(a, b, 1'b1);
        end
    endfunction

    // Max exponent calculation
    always @(*) begin
        max_exp = log2_func(in_array[0]);
        for (i = 1; i < N; i = i + 1) begin
            if (log2_func(in_array[i]) > max_exp)
                max_exp = log2_func(in_array[i]);
        end
    end

    assign exp = max_exp;

    // Output logic with conditionally computed shift amount
    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : gen_output
            wire [3:0] shift_amt;
            assign shift_amt = cond_sub(max_exp, log2_func(in_array[g]));
            assign out_array[g] = in_array[g] << shift_amt;
        end
    endgenerate

endmodule