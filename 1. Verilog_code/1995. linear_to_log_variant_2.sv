//SystemVerilog
// Top-level module: linear_to_log
module linear_to_log #(
    parameter WIDTH = 8,
    parameter LUT_SIZE = 16
)(
    input  wire [WIDTH-1:0] linear_in,
    output wire [WIDTH-1:0] log_out
);

    // Internal signals
    wire [WIDTH-1:0] lut_data   [0:LUT_SIZE-1];
    wire [WIDTH-1:0] diff_array [0:LUT_SIZE-1];
    wire [WIDTH-1:0] best_index;

    // LUT generator: Generates LUT values for log transformation
    linear_to_log_lut_gen #(
        .WIDTH(WIDTH),
        .LUT_SIZE(LUT_SIZE)
    ) u_lut_gen (
        .lut_out(lut_data)
    );

    // Difference calculator: Computes absolute difference between input and LUT
    genvar gi;
    generate
        for (gi = 0; gi < LUT_SIZE; gi = gi + 1) begin : diff_calc
            linear_to_log_sub_lut #(.WIDTH(WIDTH)) u_sub_lut (
                .a(linear_in),
                .b(lut_data[gi]),
                .diff(diff_array[gi])
            );
        end
    endgenerate

    // Minimum selector: Finds the LUT index with minimum difference and input >= lut
    linear_to_log_min_sel #(
        .WIDTH(WIDTH),
        .LUT_SIZE(LUT_SIZE)
    ) u_min_sel (
        .linear_in(linear_in),
        .lut_in(lut_data),
        .diff_in(diff_array),
        .best_idx(best_index)
    );

    assign log_out = best_index;

endmodule

// ---------------------------------------------
// LUT Generator Submodule
// Generates LUT values for log transformation
// ---------------------------------------------
module linear_to_log_lut_gen #(
    parameter WIDTH = 8,
    parameter LUT_SIZE = 16
)(
    output reg [WIDTH-1:0] lut_out [0:LUT_SIZE-1]
);
    integer i;
    initial begin
        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            lut_out[i] = (1 << (i/2)); // Simplified exponential algorithm
        end
    end
endmodule

// ---------------------------------------------
// Subtraction with LUT Submodule
// Computes a - b using simple subtraction
// ---------------------------------------------
module linear_to_log_sub_lut #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] diff
);
    assign diff = a - b;
endmodule

// ---------------------------------------------
// Minimum Selector Submodule
// Finds the minimum difference and corresponding index
// ---------------------------------------------
module linear_to_log_min_sel #(
    parameter WIDTH = 8,
    parameter LUT_SIZE = 16
)(
    input  wire [WIDTH-1:0] linear_in,
    input  wire [WIDTH-1:0] lut_in   [0:LUT_SIZE-1],
    input  wire [WIDTH-1:0] diff_in  [0:LUT_SIZE-1],
    output reg  [WIDTH-1:0] best_idx
);
    integer i;
    reg [WIDTH-1:0] min_diff;
    initial begin
        best_idx = 0;
        min_diff = {WIDTH{1'b1}};
    end

    always @* begin
        best_idx = 0;
        min_diff = {WIDTH{1'b1}};
        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            if ((linear_in >= lut_in[i]) && (diff_in[i] < min_diff)) begin
                min_diff = diff_in[i];
                best_idx = i[WIDTH-1:0];
            end
        end
    end
endmodule