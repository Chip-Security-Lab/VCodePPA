//SystemVerilog
// Top-level module: bin_to_onehot_hier
module bin_to_onehot_hier #(
    parameter BIN_WIDTH = 4
)(
    input wire [BIN_WIDTH-1:0] bin_in,
    input wire enable,
    output wire [(1<<BIN_WIDTH)-1:0] onehot_out
);

    // Internal wires for shifted values between stages
    wire [(1<<BIN_WIDTH)-1:0] shifted_value [BIN_WIDTH:0];

    // Stage 0: Initial value generator
    bin_to_onehot_init #(
        .BIN_WIDTH(BIN_WIDTH)
    ) u_init (
        .shifted_value_0(shifted_value[0])
    );

    // Shift stages: Parameterized generate block for each bit in bin_in
    genvar stage;
    generate
        for (stage = 0; stage < BIN_WIDTH; stage = stage + 1) begin : gen_shift_stages
            // Each stage processes one bit of bin_in
            bin_to_onehot_stage #(
                .BIN_WIDTH(BIN_WIDTH),
                .STAGE(stage)
            ) u_stage (
                .bin_bit(bin_in[stage]),
                .shifted_value_in(shifted_value[stage]),
                .shifted_value_out(shifted_value[stage+1])
            );
        end
    endgenerate

    // Enable logic: Output is onehot if enabled, otherwise all zeros
    bin_to_onehot_output #(
        .BIN_WIDTH(BIN_WIDTH)
    ) u_output (
        .enable(enable),
        .shifted_value_in(shifted_value[BIN_WIDTH]),
        .onehot_out(onehot_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: bin_to_onehot_init
// Function: Generates the initial shifted_value[0] with only bit 0 set to 1
// -----------------------------------------------------------------------------
module bin_to_onehot_init #(
    parameter BIN_WIDTH = 4
)(
    output wire [(1<<BIN_WIDTH)-1:0] shifted_value_0
);
    assign shifted_value_0 = {{((1<<BIN_WIDTH)-1){1'b0}}, 1'b1};
endmodule

// -----------------------------------------------------------------------------
// Submodule: bin_to_onehot_stage
// Function: Performs one stage of shifting based on one bit of bin_in
// Parameters:
//   STAGE - Which bit of bin_in this stage operates on
// -----------------------------------------------------------------------------
module bin_to_onehot_stage #(
    parameter BIN_WIDTH = 4,
    parameter STAGE = 0
)(
    input  wire bin_bit,
    input  wire [(1<<BIN_WIDTH)-1:0] shifted_value_in,
    output wire [(1<<BIN_WIDTH)-1:0] shifted_value_out
);
    genvar j;
    generate
        for (j = 0; j < (1<<BIN_WIDTH); j = j + 1) begin : gen_shift
            assign shifted_value_out[j] = bin_bit ?
                ((j >= (1<<STAGE)) ? shifted_value_in[j-(1<<STAGE)] : 1'b0) :
                shifted_value_in[j];
        end
    endgenerate
endmodule

// -----------------------------------------------------------------------------
// Submodule: bin_to_onehot_output
// Function: Applies enable and outputs final onehot result
// -----------------------------------------------------------------------------
module bin_to_onehot_output #(
    parameter BIN_WIDTH = 4
)(
    input  wire enable,
    input  wire [(1<<BIN_WIDTH)-1:0] shifted_value_in,
    output wire [(1<<BIN_WIDTH)-1:0] onehot_out
);
    assign onehot_out = enable ? shifted_value_in : {((1<<BIN_WIDTH)){1'b0}};
endmodule