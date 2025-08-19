//SystemVerilog
module shift_log_right #(parameter WIDTH=8, SHIFT=2) (
    input  [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);

    wire [WIDTH-1:0] shifted_data;
    wire [WIDTH-1:0] lut_difference;

    // Generate right-shifted data
    assign shifted_data = data_in >> SHIFT;

    // LUT-based subtractor: shifted_data - 0
    lut_subtractor_8bit u_lut_subtractor_8bit (
        .minuend(shifted_data),
        .subtrahend({WIDTH{1'b0}}),
        .difference(lut_difference)
    );

    assign data_out = lut_difference;

endmodule

module lut_subtractor_8bit (
    input  [7:0] minuend,
    input  [7:0] subtrahend,
    output [7:0] difference
);
    reg [7:0] lut_diff [0:65535];
    reg [7:0] diff_reg;

    wire [15:0] lut_addr;
    assign lut_addr = {minuend, subtrahend};

    initial begin : LUT_INIT
        integer i, j;
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                lut_diff[{i, j}] = i - j;
            end
        end
    end

    always @(*) begin
        diff_reg = lut_diff[lut_addr];
    end

    assign difference = diff_reg;

endmodule