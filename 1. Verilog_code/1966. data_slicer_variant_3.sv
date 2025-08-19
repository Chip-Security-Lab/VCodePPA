//SystemVerilog
// Top-level module: Structured Pipelined Data Slicer
module data_slicer #(
    parameter DATA_WIDTH = 32,
    parameter SLICE_WIDTH = 8,  // Must divide DATA_WIDTH evenly
    parameter NUM_SLICES = DATA_WIDTH / SLICE_WIDTH
)(
    input                          clk,
    input                          rst_n,
    input  [DATA_WIDTH-1:0]        wide_data,
    input  [$clog2(NUM_SLICES)-1:0] slice_sel,
    output [SLICE_WIDTH-1:0]       slice_out
);

    // Stage 1: Register input data and slice select for pipeline
    reg  [DATA_WIDTH-1:0]          wide_data_stage1;
    reg  [$clog2(NUM_SLICES)-1:0]  slice_sel_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wide_data_stage1  <= {DATA_WIDTH{1'b0}};
            slice_sel_stage1  <= {($clog2(NUM_SLICES)){1'b0}};
        end else begin
            wide_data_stage1  <= wide_data;
            slice_sel_stage1  <= slice_sel;
        end
    end

    // Stage 2: Extract all slices in parallel (combinational)
    wire [SLICE_WIDTH-1:0]         slice_stage2_array [0:NUM_SLICES-1];
    genvar i;
    generate
        for (i = 0; i < NUM_SLICES; i = i + 1) begin : gen_slices
            assign slice_stage2_array[i] = wide_data_stage1[i*SLICE_WIDTH +: SLICE_WIDTH];
        end
    endgenerate

    // Stage 2: Register all slices for pipeline
    reg [SLICE_WIDTH-1:0]          slice_stage2_reg [0:NUM_SLICES-1];
    reg [$clog2(NUM_SLICES)-1:0]   slice_sel_stage2;
    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (k = 0; k < NUM_SLICES; k = k + 1)
                slice_stage2_reg[k] <= {SLICE_WIDTH{1'b0}};
            slice_sel_stage2 <= {($clog2(NUM_SLICES)){1'b0}};
        end else begin
            for (k = 0; k < NUM_SLICES; k = k + 1)
                slice_stage2_reg[k] <= slice_stage2_array[k];
            slice_sel_stage2 <= slice_sel_stage1;
        end
    end

    // Stage 3: Select the required slice (combinational)
    wire [SLICE_WIDTH-1:0]         selected_slice_stage3;
    assign selected_slice_stage3 = slice_stage2_reg[slice_sel_stage2];

    // Stage 3: Register output for final pipeline stage
    reg [SLICE_WIDTH-1:0]          slice_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            slice_out_reg <= {SLICE_WIDTH{1'b0}};
        else
            slice_out_reg <= selected_slice_stage3;
    end

    // Output assignment
    assign slice_out = slice_out_reg;

endmodule