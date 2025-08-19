//SystemVerilog
// Top-level module: Structured Pipelined Barrel Shifter
module barrel_shift #(
    parameter SHIFT = 3,
    parameter WIDTH = 8
) (
    input                   clk,
    input                   rst_n,
    input  [WIDTH-1:0]      data_in,
    output [WIDTH-1:0]      data_out
);

    // Pipeline stage 1: Data concatenation
    wire [2*WIDTH-1:0]      concat_stage_data;
    reg  [2*WIDTH-1:0]      concat_stage_reg;

    // Pipeline stage 2: Barrel shift
    wire [2*WIDTH-1:0]      shift_stage_data;
    reg  [2*WIDTH-1:0]      shift_stage_reg;

    // Pipeline stage 3: Data slicing
    wire [WIDTH-1:0]        slice_stage_data;
    reg  [WIDTH-1:0]        slice_stage_reg;

    // Stage 1: Data Concatenation
    data_concatenator #(
        .WIDTH(WIDTH)
    ) u_data_concatenator (
        .in_data(data_in),
        .out_data(concat_stage_data)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            concat_stage_reg <= {2*WIDTH{1'b0}};
        else
            concat_stage_reg <= concat_stage_data;
    end

    // Stage 2: Barrel Shift
    right_shifter #(
        .SHIFT(SHIFT),
        .WIDTH(WIDTH)
    ) u_right_shifter (
        .in_data(concat_stage_reg),
        .out_data(shift_stage_data)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_stage_reg <= {2*WIDTH{1'b0}};
        else
            shift_stage_reg <= shift_stage_data;
    end

    // Stage 3: Data Slicing
    data_slicer #(
        .WIDTH(WIDTH)
    ) u_data_slicer (
        .in_data(shift_stage_reg),
        .out_data(slice_stage_data)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            slice_stage_reg <= {WIDTH{1'b0}};
        else
            slice_stage_reg <= slice_stage_data;
    end

    // Output assignment
    assign data_out = slice_stage_reg;

endmodule

// -----------------------------------------------------------------------------
// Submodule: Data Concatenator
// Function: Duplicates the input data to form a 2*WIDTH-bit vector
// -----------------------------------------------------------------------------
module data_concatenator #(
    parameter WIDTH = 8
) (
    input  [WIDTH-1:0] in_data,
    output [2*WIDTH-1:0] out_data
);
    assign out_data = {in_data, in_data};
endmodule

// -----------------------------------------------------------------------------
// Submodule: Right Shifter
// Function: Shifts the input data right by (WIDTH - SHIFT) positions
// -----------------------------------------------------------------------------
module right_shifter #(
    parameter SHIFT = 3,
    parameter WIDTH = 8
) (
    input  [2*WIDTH-1:0] in_data,
    output [2*WIDTH-1:0] out_data
);
    assign out_data = in_data >> (WIDTH - SHIFT);
endmodule

// -----------------------------------------------------------------------------
// Submodule: Data Slicer
// Function: Selects the lower WIDTH bits from the shifted data
// -----------------------------------------------------------------------------
module data_slicer #(
    parameter WIDTH = 8
) (
    input  [2*WIDTH-1:0] in_data,
    output [WIDTH-1:0] out_data
);
    assign out_data = in_data[WIDTH-1:0];
endmodule