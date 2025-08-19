//SystemVerilog
module partial_pattern_matcher #(
    parameter W = 16,
    parameter SLICE = 8
)(
    input [W-1:0] data, pattern,
    input match_upper, // Control to select which half to match
    output match_result
);
    // Internal signals
    wire upper_match, lower_match;
    
    // Instantiate submodules
    pattern_compare #(
        .WIDTH(SLICE)
    ) upper_pattern_compare (
        .data_slice(data[W-1:W-SLICE]),
        .pattern_slice(pattern[W-1:W-SLICE]),
        .match(upper_match)
    );
    
    pattern_compare #(
        .WIDTH(SLICE)
    ) lower_pattern_compare (
        .data_slice(data[SLICE-1:0]),
        .pattern_slice(pattern[SLICE-1:0]),
        .match(lower_match)
    );
    
    // Instantiate selector submodule
    match_selector match_select_unit (
        .upper_match(upper_match),
        .lower_match(lower_match),
        .select_upper(match_upper),
        .result(match_result)
    );
    
endmodule

// Parameterizable pattern comparison module using parallel prefix subtractor
module pattern_compare #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_slice,
    input [WIDTH-1:0] pattern_slice,
    output match
);
    // Internal signals for parallel prefix subtractor
    wire [WIDTH-1:0] difference;
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] p, g;
    wire [WIDTH-1:0][WIDTH-1:0] prefix_p, prefix_g;
    
    // Generate propagate and generate signals
    genvar i, j, k;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_pg_signals
            assign p[i] = data_slice[i] ^ pattern_slice[i];
            assign g[i] = ~data_slice[i] & pattern_slice[i];
        end
    endgenerate
    
    // Initial prefix computation (identity operation)
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_prefix_init
            assign prefix_p[0][i] = p[i];
            assign prefix_g[0][i] = g[i];
        end
    endgenerate
    
    // Parallel prefix computation stages (Kogge-Stone) - optimized with bit concatenation
    generate
        for (i = 1; i <= $clog2(WIDTH); i = i + 1) begin : prefix_stages
            for (j = 0; j < WIDTH; j = j + 1) begin : prefix_cells
                if (j >= (1 << (i-1))) begin
                    localparam shift_amt = 1 << (i-1);
                    assign prefix_p[i][j] = prefix_p[i-1][j] & prefix_p[i-1][j-shift_amt];
                    assign prefix_g[i][j] = prefix_g[i-1][j] | (prefix_p[i-1][j] & prefix_g[i-1][j-shift_amt]);
                end else begin
                    assign prefix_p[i][j] = prefix_p[i-1][j];
                    assign prefix_g[i][j] = prefix_g[i-1][j];
                end
            end
        end
    endgenerate
    
    // Compute borrows
    assign borrow[0] = 1'b0;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_borrows
            assign borrow[i+1] = prefix_g[$clog2(WIDTH)][i];
        end
    endgenerate
    
    // Compute difference
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_difference
            assign difference[i] = p[i] ^ borrow[i];
        end
    endgenerate
    
    // Check if difference is zero (data_slice equals pattern_slice)
    reg match_reg;
    always @(*) begin
        match_reg = (difference == {WIDTH{1'b0}});
    end
    
    assign match = match_reg;
endmodule

// Match selection module
module match_selector (
    input upper_match,
    input lower_match,
    input select_upper,
    output result
);
    // Optimized with direct mux assignment instead of registered output
    assign result = select_upper ? upper_match : lower_match;
endmodule