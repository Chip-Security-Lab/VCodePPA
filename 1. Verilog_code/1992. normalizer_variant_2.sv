//SystemVerilog
// Top-level Normalizer with hierarchical structure

module normalizer #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] in_data,
    output wire [WIDTH-1:0] normalized_data,
    output wire [$clog2(WIDTH)-1:0] shift_count
);

    // Internal signal for leading-one position
    wire [$clog2(WIDTH)-1:0] leading_one_pos;
    wire [$clog2(WIDTH)-1:0] shift_count_internal;

    // Leading-One Detector Submodule
    leading_one_detector #(
        .WIDTH(WIDTH)
    ) u_leading_one_detector (
        .data_in(in_data),
        .leading_one_pos(leading_one_pos)
    );

    // Shift-Count Calculator Submodule
    shift_count_calculator #(
        .WIDTH(WIDTH)
    ) u_shift_count_calculator (
        .leading_one_pos(leading_one_pos),
        .shift_count(shift_count_internal)
    );

    // Barrel Shifter Submodule
    barrel_shifter #(
        .WIDTH(WIDTH)
    ) u_barrel_shifter (
        .data_in(in_data),
        .shift_amt(shift_count_internal),
        .data_out(normalized_data)
    );

    // Output assignment
    assign shift_count = shift_count_internal;

endmodule

// -----------------------------------------------------------------------------
// Submodule: leading_one_detector
// Purpose  : Finds the position of the most significant '1' in the data input
// -----------------------------------------------------------------------------
module leading_one_detector #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] data_in,
    output reg  [$clog2(WIDTH)-1:0] leading_one_pos
);
    integer i;
    reg found;

    always @* begin
        found = 1'b0;
        leading_one_pos = {$clog2(WIDTH){1'b0}};
        for (i = WIDTH-1; i >= 0; i = i - 1) begin
            if (!found && data_in[i]) begin
                found = 1'b1;
                leading_one_pos = i[$clog2(WIDTH)-1:0];
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: shift_count_calculator
// Purpose  : Calculates shift amount using a LUT-based or direct subtractor
//            shift_count = WIDTH-1 - leading_one_pos
// -----------------------------------------------------------------------------
module shift_count_calculator #(
    parameter WIDTH = 16
)(
    input  wire [$clog2(WIDTH)-1:0] leading_one_pos,
    output reg  [$clog2(WIDTH)-1:0] shift_count
);

    function [7:0] lut_subtractor_8bit;
        input [7:0] minuend;
        input [7:0] subtrahend;
        reg [15:0] lut [0:255];
        reg [7:0] diff;
        integer k;
        begin
            // LUT initialization (functionally constant, synthesizable)
            for (k = 0; k < 256; k = k + 1) begin
                lut[k] = k;
            end
            diff = lut[minuend] - lut[subtrahend];
            lut_subtractor_8bit = diff;
        end
    endfunction

    always @* begin
        if ($clog2(WIDTH) <= 8) begin
            shift_count = lut_subtractor_8bit(WIDTH-1, leading_one_pos);
        end else begin
            shift_count = (WIDTH-1) - leading_one_pos;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: barrel_shifter
// Purpose  : Shifts input data to the left by shift_amt
// -----------------------------------------------------------------------------
module barrel_shifter #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] data_in,
    input  wire [$clog2(WIDTH)-1:0] shift_amt,
    output wire [WIDTH-1:0] data_out
);
    assign data_out = data_in << shift_amt;
endmodule