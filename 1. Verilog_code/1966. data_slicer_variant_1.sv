//SystemVerilog
// Top-level module: Optimized Pipelined Data Slicer
module data_slicer #(
    parameter DATA_WIDTH = 32,
    parameter SLICE_WIDTH = 8,  // Must divide DATA_WIDTH
    parameter NUM_SLICES = DATA_WIDTH / SLICE_WIDTH
)(
    input  wire                        clk,
    input  wire                        rst_n,
    input  wire [DATA_WIDTH-1:0]       wide_data,
    input  wire [$clog2(NUM_SLICES)-1:0] slice_sel,
    output wire [SLICE_WIDTH-1:0]      slice_out
);

    // Stage 1: Register Input Data
    reg [DATA_WIDTH-1:0] wide_data_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wide_data_reg <= {DATA_WIDTH{1'b0}};
        else
            wide_data_reg <= wide_data;
    end

    // Stage 2: Register Slice Selector
    reg [$clog2(NUM_SLICES)-1:0] slice_sel_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            slice_sel_reg <= {$clog2(NUM_SLICES){1'b0}};
        else
            slice_sel_reg <= slice_sel;
    end

    // Stage 3: Extract and Register Selected Slice
    reg [SLICE_WIDTH-1:0] selected_slice_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            selected_slice_reg <= {SLICE_WIDTH{1'b0}};
        else
            selected_slice_reg <= wide_data_reg >> (slice_sel_reg * SLICE_WIDTH);
    end

    assign slice_out = selected_slice_reg[SLICE_WIDTH-1:0];

endmodule