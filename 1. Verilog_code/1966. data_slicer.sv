module data_slicer #(
    parameter DATA_WIDTH = 32,
    parameter SLICE_WIDTH = 8,  // 必须能整除DATA_WIDTH
    parameter NUM_SLICES = DATA_WIDTH/SLICE_WIDTH
)(
    input [DATA_WIDTH-1:0] wide_data,
    input [$clog2(NUM_SLICES)-1:0] slice_sel,
    output [SLICE_WIDTH-1:0] slice_out
);
    assign slice_out = wide_data[slice_sel*SLICE_WIDTH +: SLICE_WIDTH];
endmodule