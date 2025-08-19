//SystemVerilog
// Top-level module: linear_to_log
// Function: Converts linear input to logarithmic output using a LUT and minimum difference search.
// Structure: Hierarchical, with separate LUT and log calculation submodules.

module linear_to_log #(
    parameter WIDTH = 8,
    parameter LUT_SIZE = 16
)(
    input  wire [WIDTH-1:0] linear_in,
    output wire [WIDTH-1:0] log_out
);

    // Internal connection signals
    wire [WIDTH-1:0] lut_values [0:LUT_SIZE-1];
    wire [WIDTH-1:0] log_calc_out;

    // LUT Generation Submodule
    lut_gen #(
        .WIDTH(WIDTH),
        .LUT_SIZE(LUT_SIZE)
    ) u_lut_gen (
        .lut_out(lut_values)
    );

    // Logarithm Calculation Submodule
    log_calc #(
        .WIDTH(WIDTH),
        .LUT_SIZE(LUT_SIZE)
    ) u_log_calc (
        .linear_in(linear_in),
        .lut_in(lut_values),
        .log_out(log_calc_out)
    );

    // Output assignment
    assign log_out = log_calc_out;

endmodule

// --------------------------------------------------------------
// Submodule: lut_gen
// Function: Generates a LUT for exponential mapping
// --------------------------------------------------------------
module lut_gen #(
    parameter WIDTH = 8,
    parameter LUT_SIZE = 16
)(
    output reg [WIDTH-1:0] lut_out [0:LUT_SIZE-1]
);
    integer idx_lut;
    initial begin
        idx_lut = 0;
        while (idx_lut < LUT_SIZE) begin
            lut_out[idx_lut] = (1 << (idx_lut/2)); // Simplified exponential algorithm
            idx_lut = idx_lut + 1;
        end
    end
endmodule

// --------------------------------------------------------------
// Submodule: log_calc
// Function: Finds the LUT index with minimum difference to linear_in
// --------------------------------------------------------------
module log_calc #(
    parameter WIDTH = 8,
    parameter LUT_SIZE = 16
)(
    input  wire [WIDTH-1:0] linear_in,
    input  wire [WIDTH-1:0] lut_in [0:LUT_SIZE-1],
    output reg  [WIDTH-1:0] log_out
);
    integer idx_log;
    reg [WIDTH-1:0] min_diff;
    reg [WIDTH-1:0] diff;
    reg [$clog2(LUT_SIZE)-1:0] best_idx;

    always @* begin
        best_idx = 0;
        min_diff = {WIDTH{1'b1}};
        idx_log = 0;
        while (idx_log < LUT_SIZE) begin
            if (linear_in >= lut_in[idx_log]) begin
                diff = linear_in - lut_in[idx_log];
                if (diff < min_diff) begin
                    min_diff = diff;
                    best_idx = idx_log[$clog2(LUT_SIZE)-1:0];
                end
            end
            idx_log = idx_log + 1;
        end
        log_out = {{(WIDTH-$clog2(LUT_SIZE)){1'b0}}, best_idx};
    end
endmodule