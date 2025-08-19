//SystemVerilog
module shift_add_mult (
    input [7:0] mplier, mcand,
    output [15:0] result
);
    wire [15:0] shifted_mcand [7:0];
    wire [15:0] partial_sum [7:0];
    
    // Barrel shifter implementation
    assign shifted_mcand[0] = {8'b0, mcand};
    assign shifted_mcand[1] = {7'b0, mcand, 1'b0};
    assign shifted_mcand[2] = {6'b0, mcand, 2'b0};
    assign shifted_mcand[3] = {5'b0, mcand, 3'b0};
    assign shifted_mcand[4] = {4'b0, mcand, 4'b0};
    assign shifted_mcand[5] = {3'b0, mcand, 5'b0};
    assign shifted_mcand[6] = {2'b0, mcand, 6'b0};
    assign shifted_mcand[7] = {1'b0, mcand, 7'b0};
    
    // Conditional addition using multiplexers
    assign partial_sum[0] = mplier[0] ? shifted_mcand[0] : 16'b0;
    assign partial_sum[1] = mplier[1] ? shifted_mcand[1] : 16'b0;
    assign partial_sum[2] = mplier[2] ? shifted_mcand[2] : 16'b0;
    assign partial_sum[3] = mplier[3] ? shifted_mcand[3] : 16'b0;
    assign partial_sum[4] = mplier[4] ? shifted_mcand[4] : 16'b0;
    assign partial_sum[5] = mplier[5] ? shifted_mcand[5] : 16'b0;
    assign partial_sum[6] = mplier[6] ? shifted_mcand[6] : 16'b0;
    assign partial_sum[7] = mplier[7] ? shifted_mcand[7] : 16'b0;
    
    // Final addition
    assign result = partial_sum[0] + partial_sum[1] + partial_sum[2] + partial_sum[3] +
                   partial_sum[4] + partial_sum[5] + partial_sum[6] + partial_sum[7];
endmodule