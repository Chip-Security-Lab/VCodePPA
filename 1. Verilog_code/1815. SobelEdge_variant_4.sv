//SystemVerilog
module SobelEdge #(parameter W=8) (
    input clk,
    input [W-1:0] pixel_in,
    output reg [W+1:0] gradient
);
    reg [W-1:0] window [2:8];
    reg [W-1:0] pixel_reg;
    wire [W+1:0] gradient_comb;
    integer i;
    
    // Register input in first stage
    always @(posedge clk) begin
        pixel_reg <= pixel_in;
    end
    
    // Shift window registers in second stage
    always @(posedge clk) begin
        for(i=8; i>2; i=i-1)
            window[i] <= window[i-1];
        window[2] <= pixel_reg;
    end
    
    // Register the output
    always @(posedge clk) begin
        gradient <= gradient_comb;
    end
    
    // Compute gradient combinationally
    // Now using pixel_reg instead of window[1]
    assign gradient_comb = (pixel_reg + (window[3] << 1) + window[6]) - 
                          (window[2] + (window[5] << 1) + window[8]);
endmodule