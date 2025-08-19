//SystemVerilog
module WaveletFilter #(parameter W=8) (
    input clk,
    input [W-1:0] din,
    output reg [W-1:0] approx, detail
);
    reg [W-1:0] prev_sample;
    reg [W:0] sum; // One bit wider to handle addition
    
    always @(posedge clk) begin
        // Pre-compute the sum in a separate register
        sum <= {1'b0, din} + {1'b0, prev_sample};
        // Use pre-computed sum for approx
        approx <= sum[W:1]; // Right shift by 1 (divide by 2)
        // Calculate detail directly
        detail <= din - prev_sample;
        // Update previous sample
        prev_sample <= din;
    end
endmodule