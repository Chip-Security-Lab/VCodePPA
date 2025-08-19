module ring_oscillator #(
    parameter STAGES = 5,     // Number of inverter stages (odd)
    parameter DELAY_PS = 200  // Approximate stage delay in picoseconds
)(
    input enable,
    output clk_out
);
    wire [STAGES:0] inv_chain;
    
    assign inv_chain[0] = enable ? inv_chain[STAGES] : 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : inverter_stage
            not #(DELAY_PS) inv (inv_chain[i+1], inv_chain[i]);
        end
    endgenerate
    
    assign clk_out = inv_chain[STAGES];
endmodule