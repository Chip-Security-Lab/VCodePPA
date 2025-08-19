//SystemVerilog
// Top-level Module: onehot2bin
module onehot2bin #(
    parameter OH_WIDTH = 8,
    parameter OUT_WIDTH = 3 // Output width
)(
    input  wire [OH_WIDTH-1:0] onehot_in,
    output wire [OUT_WIDTH-1:0] bin_out
);

    // Internal signals
    wire [OUT_WIDTH-1:0] case_bin;
    wire [OUT_WIDTH-1:0] default_bin;
    wire                 is_legal_onehot;

    // Submodule: One-Hot to Binary Case Decoder
    onehot2bin_case_decoder #(
        .OH_WIDTH (OH_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) u_case_decoder (
        .onehot_in (onehot_in),
        .bin_case  (case_bin)
    );

    // Submodule: One-Hot Legality Checker
    onehot_legality_checker #(
        .OH_WIDTH (OH_WIDTH)
    ) u_legality_checker (
        .onehot_in      (onehot_in),
        .is_legal_onehot(is_legal_onehot)
    );

    // Submodule: Default Binary Output Generator
    onehot2bin_default #(
        .OUT_WIDTH(OUT_WIDTH)
    ) u_default_bin (
        .is_legal_onehot(is_legal_onehot),
        .bin_default    (default_bin)
    );

    // Output selection logic
    assign bin_out = (case_bin !== {OUT_WIDTH{1'bx}}) ? case_bin : default_bin;

endmodule

// -----------------------------------------------------------------------------
// Submodule: onehot2bin_case_decoder
// Function: Decodes a fixed-width one-hot input into its equivalent binary value.
// If input does not match any legal one-hot value, outputs all 'x'.
// -----------------------------------------------------------------------------
module onehot2bin_case_decoder #(
    parameter OH_WIDTH = 8,
    parameter OUT_WIDTH = 3
)(
    input  wire [OH_WIDTH-1:0] onehot_in,
    output reg  [OUT_WIDTH-1:0] bin_case
);
    always @(*) begin
        case (onehot_in)
            8'b00000001: bin_case = 3'd0;
            8'b00000010: bin_case = 3'd1;
            8'b00000100: bin_case = 3'd2;
            8'b00001000: bin_case = 3'd3;
            8'b00010000: bin_case = 3'd4;
            8'b00100000: bin_case = 3'd5;
            8'b01000000: bin_case = 3'd6;
            8'b10000000: bin_case = 3'd7;
            default:     bin_case = {OUT_WIDTH{1'bx}}; // Indicate no match
        endcase
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: onehot_legality_checker
// Function: Checks if input is a legal one-hot value (only one '1', not zero, no x/z).
// -----------------------------------------------------------------------------
module onehot_legality_checker #(
    parameter OH_WIDTH = 8
)(
    input  wire [OH_WIDTH-1:0] onehot_in,
    output wire                is_legal_onehot
);
    assign is_legal_onehot = ((onehot_in & (onehot_in - 1)) == 0) &&
                             (onehot_in != 0) &&
                             (^onehot_in !== 1'bx) &&
                             (^onehot_in !== 1'bz);
endmodule

// -----------------------------------------------------------------------------
// Submodule: onehot2bin_default
// Function: Generates the default binary output based on legality of one-hot input.
// If legal but not matched, outputs all 0s; if illegal, also outputs all 0s.
// -----------------------------------------------------------------------------
module onehot2bin_default #(
    parameter OUT_WIDTH = 3
)(
    input  wire is_legal_onehot,
    output wire [OUT_WIDTH-1:0] bin_default
);
    assign bin_default = {OUT_WIDTH{1'b0}};
endmodule