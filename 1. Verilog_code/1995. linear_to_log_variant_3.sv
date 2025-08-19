//SystemVerilog
// Top-level module: linear_to_log
// Function: Converts linear input to logarithmic output using LUT and index finder submodules

module linear_to_log #(
    parameter WIDTH = 8,
    parameter LUT_SIZE = 16
)(
    input  wire [WIDTH-1:0] linear_in,
    output wire [WIDTH-1:0] log_out
);

    // Internal signals
    wire [WIDTH-1:0] lut_data [0:LUT_SIZE-1];
    wire [$clog2(LUT_SIZE)-1:0] best_index;

    // LUT generator instance
    lut_generator #(
        .WIDTH(WIDTH),
        .LUT_SIZE(LUT_SIZE)
    ) u_lut_generator (
        .lut_out(lut_data)
    );

    // Index finder instance
    log_index_finder #(
        .WIDTH(WIDTH),
        .LUT_SIZE(LUT_SIZE)
    ) u_log_index_finder (
        .linear_in(linear_in),
        .lut(lut_data),
        .best_idx(best_index)
    );

    // Assign to output, padding index if necessary
    assign log_out = {{(WIDTH-$clog2(LUT_SIZE)){1'b0}}, best_index};

endmodule

// Submodule: lut_generator
// Function: Generates LUT with simplified exponential mapping
module lut_generator #(
    parameter WIDTH = 8,
    parameter LUT_SIZE = 16
)(
    output reg [WIDTH-1:0] lut_out [0:LUT_SIZE-1]
);
    integer i;
    initial begin
        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            lut_out[i] = (1 << (i/2));
        end
    end
endmodule

// Submodule: subtractor_lut
// Function: Performs 8-bit subtraction using LUT-based method
module subtractor_lut (
    input  wire [7:0] minuend,
    input  wire [7:0] subtrahend,
    output wire [7:0] difference
);
    reg [7:0] lut_sub [0:255][0:255];
    reg [7:0] diff_reg;

    integer idx_i, idx_j;

    initial begin
        for (idx_i = 0; idx_i < 256; idx_i = idx_i + 1) begin
            for (idx_j = 0; idx_j < 256; idx_j = idx_j + 1) begin
                lut_sub[idx_i][idx_j] = idx_i - idx_j;
            end
        end
    end

    always @(*) begin
        diff_reg = lut_sub[minuend][subtrahend];
    end

    assign difference = diff_reg;

endmodule

// Submodule: log_index_finder
// Function: Finds the index in LUT closest to but not greater than the linear input using LUT-based subtraction
module log_index_finder #(
    parameter WIDTH = 8,
    parameter LUT_SIZE = 16
)(
    input  wire [WIDTH-1:0] linear_in,
    input  wire [WIDTH-1:0] lut [0:LUT_SIZE-1],
    output reg [$clog2(LUT_SIZE)-1:0] best_idx
);
    integer i;
    reg [WIDTH-1:0] min_diff;
    wire [WIDTH-1:0] diff [0:LUT_SIZE-1];
    reg [WIDTH-1:0] diff_reg [0:LUT_SIZE-1];
    reg [LUT_SIZE-1:0] valid_mask;

    genvar gv;
    generate
        for (gv = 0; gv < LUT_SIZE; gv = gv + 1) begin : gen_sub_lut
            wire [WIDTH-1:0] sub_diff;
            subtractor_lut u_subtractor_lut (
                .minuend(linear_in),
                .subtrahend(lut[gv]),
                .difference(sub_diff)
            );
            assign diff[gv] = sub_diff;
        end
    endgenerate

    always @* begin
        min_diff = {WIDTH{1'b1}};
        best_idx = 0;
        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            diff_reg[i] = diff[i];
            valid_mask[i] = (linear_in >= lut[i]);
        end
        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            if (valid_mask[i] && (diff_reg[i] < min_diff)) begin
                min_diff = diff_reg[i];
                best_idx = i[$clog2(LUT_SIZE)-1:0];
            end
        end
    end
endmodule