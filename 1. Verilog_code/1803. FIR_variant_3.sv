//SystemVerilog
module FIR #(parameter W=8) (
    input clk, 
    input [W-1:0] sample,
    output reg [W+3:0] y
);
    parameter [3:0] COEFFS = 4'hA;
    
    reg [W-1:0] delay_line [0:3];
    reg [W+3:0] partial_sum [0:3];
    reg [W+3:0] sum_01, sum_23;
    integer i;
    
    always @(posedge clk) begin
        for(i=3; i>0; i=i-1)
            delay_line[i] <= delay_line[i-1];
        delay_line[0] <= sample;
    end
    
    always @(posedge clk) begin
        for(i=0; i<4; i=i+1)
            partial_sum[i] <= delay_line[i] * COEFFS[i];
            
        sum_01 <= partial_sum[0] + partial_sum[1];
        sum_23 <= partial_sum[2] + partial_sum[3];
    end
    
    always @(posedge clk) begin
        y <= sum_01 + sum_23;
    end
endmodule