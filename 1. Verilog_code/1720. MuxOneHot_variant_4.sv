//SystemVerilog
module MuxOneHot #(parameter W=4, N=8) (
    input [N-1:0] hot_sel,
    input [N-1:0][W-1:0] channels,
    output [W-1:0] selected
);

    // Optimized parallel selection using bitwise operations
    wire [W-1:0] selected;
    wire [N-1:0][W-1:0] masked_channels;
    
    // Single stage implementation with reduced logic depth
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin
            assign masked_channels[i] = channels[i] & {W{hot_sel[i]}};
        end
    endgenerate

    // Optimized OR reduction using bitwise operations
    assign selected = masked_channels[0] | masked_channels[1] | masked_channels[2] | masked_channels[3] |
                     masked_channels[4] | masked_channels[5] | masked_channels[6] | masked_channels[7];

endmodule