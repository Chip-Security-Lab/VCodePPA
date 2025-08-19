//SystemVerilog
module MuxOneHot #(
    parameter W = 4,    // Data width
    parameter N = 8     // Number of channels
) (
    input wire [N-1:0] hot_sel,           // One-hot select signal
    input wire [N-1:0][W-1:0] channels,   // Input data channels
    output wire [W-1:0] selected          // Selected output
);

    // Intermediate signals for pipeline stages
    wire [N-1:0][W-1:0] masked_channels;
    wire [W-1:0] or_reduction;

    // Stage 1: Channel masking
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : channel_mask
            assign masked_channels[i] = channels[i] & {W{hot_sel[i]}};
        end
    endgenerate

    // Stage 2: Bit-wise OR reduction
    assign or_reduction = |masked_channels;

    // Output stage
    assign selected = or_reduction;

endmodule