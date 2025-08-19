//SystemVerilog
module block_fp #(
    parameter N = 4,
    parameter W = 16
)(
    input  [W-1:0] in_array [0:N-1],
    output [W+3:0] out_array [0:N-1],
    output [3:0] exp
);

    // Internal signals
    wire [3:0] input_exp [0:N-1];
    reg  [3:0] max_exponent;
    wire [3:0] exp_diff [0:N-1];

    // Output assignment
    assign exp = max_exponent;

    // Log2 Calculation: Generate block for input_exp
    genvar idx_log2;
    generate
        for (idx_log2 = 0; idx_log2 < N; idx_log2 = idx_log2 + 1) begin : LOG2_GEN
            log2_func_inst #(
                .W(W)
            ) u_log2_func (
                .value(in_array[idx_log2]),
                .log2_value(input_exp[idx_log2])
            );
        end
    endgenerate

    // Max Exponent Calculation (independent always block)
    integer i;
    reg [3:0] temp_max_exp;
    always @(*) begin
        temp_max_exp = input_exp[0];
        for (i = 1; i < N; i = i + 1) begin
            if (input_exp[i] > temp_max_exp)
                temp_max_exp = input_exp[i];
        end
        max_exponent = temp_max_exp;
    end

    // Subtractor: LUT-based, instantiated per element
    genvar idx_sub;
    generate
        for (idx_sub = 0; idx_sub < N; idx_sub = idx_sub + 1) begin : SUB_GEN
            lut_sub4 u_lut_sub4 (
                .a(max_exponent),
                .b(input_exp[idx_sub]),
                .diff(exp_diff[idx_sub])
            );
        end
    endgenerate

    // Output Logic: assign per element
    genvar idx_out;
    generate
        for (idx_out = 0; idx_out < N; idx_out = idx_out + 1) begin : OUT_GEN
            assign out_array[idx_out] = in_array[idx_out] << exp_diff[idx_out];
        end
    endgenerate

endmodule

// log2 function as a module
module log2_func_inst #(
    parameter W = 16
)(
    input  [W-1:0] value,
    output [3:0]   log2_value
);
    integer j;
    reg [3:0] log2_result;
    reg found;
    always @(*) begin
        log2_result = 0;
        found = 0;
        for (j = W-1; j >= 0; j = j - 1) begin
            if (value[j] && !found) begin
                log2_result = j[3:0];
                found = 1;
            end
        end
    end
    assign log2_value = log2_result;
endmodule

// 4-bit LUT-based subtractor module
module lut_sub4 (
    input  [3:0] a,
    input  [3:0] b,
    output [3:0] diff
);
    reg [3:0] sub_lut [0:255];
    initial begin : init_lut
        integer idx_a, idx_b;
        for (idx_a = 0; idx_a < 16; idx_a = idx_a + 1) begin
            for (idx_b = 0; idx_b < 16; idx_b = idx_b + 1) begin
                sub_lut[{idx_a, idx_b}] = idx_a - idx_b;
            end
        end
    end
    assign diff = sub_lut[{a, b}];
endmodule