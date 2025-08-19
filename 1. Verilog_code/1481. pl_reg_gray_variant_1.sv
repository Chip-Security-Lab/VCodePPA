//SystemVerilog
module pl_reg_gray #(parameter W=4) (
    input clk, en,
    input [W-1:0] bin_in,
    output reg [W-1:0] gray_out
);
    wire [W-1:0] gray_comb;
    
    // Pre-compute gray code combinationally from input directly
    assign gray_comb = bin_in ^ (bin_in >> 1);
    
    // Single output register stage (moved forward)
    always @(posedge clk)
        if (en) gray_out <= gray_comb;
endmodule