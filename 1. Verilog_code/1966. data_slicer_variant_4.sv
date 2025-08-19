//SystemVerilog
// Top-level module: Hierarchical data slicer with pipelined stages

module data_slicer #(
    parameter DATA_WIDTH = 32,
    parameter SLICE_WIDTH = 8,  // Must divide DATA_WIDTH evenly
    parameter NUM_SLICES = DATA_WIDTH/SLICE_WIDTH
)(
    input  wire                       clk,
    input  wire [DATA_WIDTH-1:0]      wide_data,
    input  wire [$clog2(NUM_SLICES)-1:0] slice_sel,
    output wire [SLICE_WIDTH-1:0]     slice_out
);

    // Stage 1 pipeline registers
    wire [DATA_WIDTH-1:0]      wide_data_stage1;
    wire [$clog2(NUM_SLICES)-1:0] slice_sel_stage1;

    // Stage 2 pipeline register
    wire [SLICE_WIDTH-1:0]     slice_data_stage2;

    // Pipeline Stage 1: Capture input data and slice selection
    data_slicer_stage1 #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_SLICES(NUM_SLICES)
    ) u_stage1 (
        .clk            (clk),
        .wide_data_in   (wide_data),
        .slice_sel_in   (slice_sel),
        .wide_data_out  (wide_data_stage1),
        .slice_sel_out  (slice_sel_stage1)
    );

    // Pipeline Stage 2: Slice extraction
    data_slicer_stage2 #(
        .DATA_WIDTH(DATA_WIDTH),
        .SLICE_WIDTH(SLICE_WIDTH),
        .NUM_SLICES(NUM_SLICES)
    ) u_stage2 (
        .clk            (clk),
        .wide_data_in   (wide_data_stage1),
        .slice_sel_in   (slice_sel_stage1),
        .slice_data_out (slice_data_stage2)
    );

    // Output assignment
    assign slice_out = slice_data_stage2;

endmodule

// -----------------------------------------------------------------------------
// Pipeline Stage 1: Register input data and slice selection
// -----------------------------------------------------------------------------
module data_slicer_stage1 #(
    parameter DATA_WIDTH = 32,
    parameter NUM_SLICES = 4
)(
    input  wire                       clk,
    input  wire [DATA_WIDTH-1:0]      wide_data_in,
    input  wire [$clog2(NUM_SLICES)-1:0] slice_sel_in,
    output reg  [DATA_WIDTH-1:0]      wide_data_out,
    output reg  [$clog2(NUM_SLICES)-1:0] slice_sel_out
);
    // Registers input wide data and slice select signal
    always @(posedge clk) begin
        wide_data_out   <= wide_data_in;
        slice_sel_out   <= slice_sel_in;
    end
endmodule

// -----------------------------------------------------------------------------
// Pipeline Stage 2: Extracts the selected data slice
// -----------------------------------------------------------------------------
module data_slicer_stage2 #(
    parameter DATA_WIDTH = 32,
    parameter SLICE_WIDTH = 8,
    parameter NUM_SLICES = 4
)(
    input  wire                       clk,
    input  wire [DATA_WIDTH-1:0]      wide_data_in,
    input  wire [$clog2(NUM_SLICES)-1:0] slice_sel_in,
    output reg  [SLICE_WIDTH-1:0]     slice_data_out
);
    // Extracts the selected data slice based on slice_sel_in
    always @(posedge clk) begin
        slice_data_out <= wide_data_in[slice_sel_in*SLICE_WIDTH +: SLICE_WIDTH];
    end
endmodule