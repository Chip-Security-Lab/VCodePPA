//SystemVerilog
// Top-level module: masked_shifter
// Function: Hierarchically shifts input data by a specified amount, then masks shifted and unshifted bits according to 'mask'
module masked_shifter (
    input  wire [31:0] data_in,
    input  wire [31:0] mask,
    input  wire [4:0]  shift,
    output wire [31:0] data_out
);

    // Internal signals for inter-module connections
    wire [31:0] shifted_data;
    wire [31:0] masked_shifted_data;
    wire [31:0] masked_original_data;

    // Shift Unit: Performs left shift operation using barrel shifter
    shifter_unit #(
        .DATA_WIDTH(32)
    ) u_shifter_unit (
        .in_data(data_in),
        .shift_amt(shift),
        .out_data(shifted_data)
    );

    // Mask Unit: Applies mask to shifted data
    mask_unit #(
        .DATA_WIDTH(32)
    ) u_mask_shifted (
        .in_data(shifted_data),
        .mask(mask),
        .masked_data(masked_shifted_data)
    );

    // Mask Unit: Applies inverted mask to original data
    mask_unit #(
        .DATA_WIDTH(32)
    ) u_mask_original (
        .in_data(data_in),
        .mask(~mask),
        .masked_data(masked_original_data)
    );

    // Combine masked results to form final output
    assign data_out = masked_shifted_data | masked_original_data;

endmodule

// -----------------------------------------------------------------------------
// Submodule: shifter_unit
// Function: Parameterized left barrel shifter (using mux-based structure)
// -----------------------------------------------------------------------------
module shifter_unit #(
    parameter DATA_WIDTH = 32
) (
    input  wire [DATA_WIDTH-1:0] in_data,
    input  wire [4:0]            shift_amt,
    output wire [DATA_WIDTH-1:0] out_data
);

    wire [DATA_WIDTH-1:0] stage_0;
    wire [DATA_WIDTH-1:0] stage_1;
    wire [DATA_WIDTH-1:0] stage_2;
    wire [DATA_WIDTH-1:0] stage_3;
    wire [DATA_WIDTH-1:0] stage_4;

    // Stage 0: Shift by 1 if shift_amt[0] is set
    genvar i0;
    generate
        for (i0 = 0; i0 < DATA_WIDTH; i0 = i0 + 1) begin : gen_stage0
            assign stage_0[i0] = shift_amt[0] ? ((i0 >= 1) ? in_data[i0-1] : 1'b0) : in_data[i0];
        end
    endgenerate

    // Stage 1: Shift by 2 if shift_amt[1] is set
    genvar i1;
    generate
        for (i1 = 0; i1 < DATA_WIDTH; i1 = i1 + 1) begin : gen_stage1
            assign stage_1[i1] = shift_amt[1] ? ((i1 >= 2) ? stage_0[i1-2] : 1'b0) : stage_0[i1];
        end
    endgenerate

    // Stage 2: Shift by 4 if shift_amt[2] is set
    genvar i2;
    generate
        for (i2 = 0; i2 < DATA_WIDTH; i2 = i2 + 1) begin : gen_stage2
            assign stage_2[i2] = shift_amt[2] ? ((i2 >= 4) ? stage_1[i2-4] : 1'b0) : stage_1[i2];
        end
    endgenerate

    // Stage 3: Shift by 8 if shift_amt[3] is set
    genvar i3;
    generate
        for (i3 = 0; i3 < DATA_WIDTH; i3 = i3 + 1) begin : gen_stage3
            assign stage_3[i3] = shift_amt[3] ? ((i3 >= 8) ? stage_2[i3-8] : 1'b0) : stage_2[i3];
        end
    endgenerate

    // Stage 4: Shift by 16 if shift_amt[4] is set
    genvar i4;
    generate
        for (i4 = 0; i4 < DATA_WIDTH; i4 = i4 + 1) begin : gen_stage4
            assign stage_4[i4] = shift_amt[4] ? ((i4 >= 16) ? stage_3[i4-16] : 1'b0) : stage_3[i4];
        end
    endgenerate

    assign out_data = stage_4;

endmodule

// -----------------------------------------------------------------------------
// Submodule: mask_unit
// Function: Bitwise AND mask operation
// -----------------------------------------------------------------------------
module mask_unit #(
    parameter DATA_WIDTH = 32
) (
    input  wire [DATA_WIDTH-1:0] in_data,
    input  wire [DATA_WIDTH-1:0] mask,
    output wire [DATA_WIDTH-1:0] masked_data
);
    assign masked_data = in_data & mask;
endmodule