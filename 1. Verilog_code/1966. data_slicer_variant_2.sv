//SystemVerilog
module data_slicer #(
    parameter DATA_WIDTH = 32,
    parameter SLICE_WIDTH = 8,  // 必须能整除DATA_WIDTH
    parameter NUM_SLICES = DATA_WIDTH/SLICE_WIDTH
)(
    input  [DATA_WIDTH-1:0] wide_data,
    input  [$clog2(NUM_SLICES)-1:0] slice_sel,
    output reg [SLICE_WIDTH-1:0] slice_out
);

    integer i;
    always @(*) begin
        slice_out = {SLICE_WIDTH{1'b0}};
        for (i = 0; i < NUM_SLICES; i = i + 1) begin
            if (slice_sel == i)
                slice_out = wide_data[i*SLICE_WIDTH +: SLICE_WIDTH];
        end
    end

endmodule