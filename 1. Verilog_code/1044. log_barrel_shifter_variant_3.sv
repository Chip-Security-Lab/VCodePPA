//SystemVerilog
// Hierarchical, modular barrel shifter

//-----------------------------------------------------------------------------
// Barrel Shifter Stage Module
// Performs shift by a single stage (2^SHIFT_INDEX) if shift_bit is set
//-----------------------------------------------------------------------------
module barrel_shifter_stage #(
    parameter WIDTH = 32,
    parameter SHIFT_INDEX = 0
) (
    input  wire [WIDTH-1:0] stage_in,
    input  wire             shift_bit,
    output wire [WIDTH-1:0] stage_out
);
    localparam SHIFT_AMOUNT = (1 << SHIFT_INDEX);

    // If shift amount exceeds WIDTH, just output zeros
    generate
        if (SHIFT_AMOUNT < WIDTH) begin : gen_valid_shift
            assign stage_out = shift_bit ? {stage_in[WIDTH-SHIFT_AMOUNT-1:0], {SHIFT_AMOUNT{1'b0}}} : stage_in;
        end else begin : gen_invalid_shift
            assign stage_out = shift_bit ? {WIDTH{1'b0}} : stage_in;
        end
    endgenerate
endmodule

//-----------------------------------------------------------------------------
// Barrel Shifter Output Selector
// Selects the correct output based on STAGE_COUNT
//-----------------------------------------------------------------------------
module barrel_shifter_output_select #(
    parameter WIDTH = 32,
    parameter STAGE_COUNT = 6
) (
    input  wire [WIDTH-1:0] in_data,
    input  wire [WIDTH-1:0] stage0_out,
    input  wire [WIDTH-1:0] stage1_out,
    input  wire [WIDTH-1:0] stage2_out,
    input  wire [WIDTH-1:0] stage3_out,
    input  wire [WIDTH-1:0] stage4_out,
    input  wire [WIDTH-1:0] stage5_out,
    output wire [WIDTH-1:0] out_data
);
    generate
        if (STAGE_COUNT == 0) begin : gen_out0
            assign out_data = in_data;
        end else if (STAGE_COUNT == 1) begin : gen_out1
            assign out_data = stage0_out;
        end else if (STAGE_COUNT == 2) begin : gen_out2
            assign out_data = stage1_out;
        end else if (STAGE_COUNT == 3) begin : gen_out3
            assign out_data = stage2_out;
        end else if (STAGE_COUNT == 4) begin : gen_out4
            assign out_data = stage3_out;
        end else if (STAGE_COUNT == 5) begin : gen_out5
            assign out_data = stage4_out;
        end else begin : gen_out6
            assign out_data = stage5_out;
        end
    endgenerate
endmodule

//-----------------------------------------------------------------------------
// Top-Level Log Barrel Shifter Module
//-----------------------------------------------------------------------------
module log_barrel_shifter #(
    parameter WIDTH = 32
) (
    input  wire [WIDTH-1:0]             in_data,
    input  wire [$clog2(WIDTH)-1:0]     shift,
    output wire [WIDTH-1:0]             out_data
);

    localparam STAGE_COUNT = $clog2(WIDTH);

    // Internal wires for stage outputs
    wire [WIDTH-1:0] stage_out [0:5];

    // Instantiate Barrel Shifter Stages
    generate
        if (STAGE_COUNT > 0) begin : gen_stage0
            barrel_shifter_stage #(
                .WIDTH(WIDTH),
                .SHIFT_INDEX(0)
            ) u_stage0 (
                .stage_in  (in_data),
                .shift_bit (shift[0]),
                .stage_out (stage_out[0])
            );
        end else begin : gen_stage0_none
            assign stage_out[0] = in_data;
        end

        if (STAGE_COUNT > 1) begin : gen_stage1
            barrel_shifter_stage #(
                .WIDTH(WIDTH),
                .SHIFT_INDEX(1)
            ) u_stage1 (
                .stage_in  (stage_out[0]),
                .shift_bit (shift[1]),
                .stage_out (stage_out[1])
            );
        end else begin : gen_stage1_none
            assign stage_out[1] = stage_out[0];
        end

        if (STAGE_COUNT > 2) begin : gen_stage2
            barrel_shifter_stage #(
                .WIDTH(WIDTH),
                .SHIFT_INDEX(2)
            ) u_stage2 (
                .stage_in  (stage_out[1]),
                .shift_bit (shift[2]),
                .stage_out (stage_out[2])
            );
        end else begin : gen_stage2_none
            assign stage_out[2] = stage_out[1];
        end

        if (STAGE_COUNT > 3) begin : gen_stage3
            barrel_shifter_stage #(
                .WIDTH(WIDTH),
                .SHIFT_INDEX(3)
            ) u_stage3 (
                .stage_in  (stage_out[2]),
                .shift_bit (shift[3]),
                .stage_out (stage_out[3])
            );
        end else begin : gen_stage3_none
            assign stage_out[3] = stage_out[2];
        end

        if (STAGE_COUNT > 4) begin : gen_stage4
            barrel_shifter_stage #(
                .WIDTH(WIDTH),
                .SHIFT_INDEX(4)
            ) u_stage4 (
                .stage_in  (stage_out[3]),
                .shift_bit (shift[4]),
                .stage_out (stage_out[4])
            );
        end else begin : gen_stage4_none
            assign stage_out[4] = stage_out[3];
        end

        if (STAGE_COUNT > 5) begin : gen_stage5
            barrel_shifter_stage #(
                .WIDTH(WIDTH),
                .SHIFT_INDEX(5)
            ) u_stage5 (
                .stage_in  (stage_out[4]),
                .shift_bit (shift[5]),
                .stage_out (stage_out[5])
            );
        end else begin : gen_stage5_none
            assign stage_out[5] = stage_out[4];
        end
    endgenerate

    // Output selection
    barrel_shifter_output_select #(
        .WIDTH(WIDTH),
        .STAGE_COUNT(STAGE_COUNT)
    ) u_output_select (
        .in_data     (in_data),
        .stage0_out  (stage_out[0]),
        .stage1_out  (stage_out[1]),
        .stage2_out  (stage_out[2]),
        .stage3_out  (stage_out[3]),
        .stage4_out  (stage_out[4]),
        .stage5_out  (stage_out[5]),
        .out_data    (out_data)
    );

endmodule