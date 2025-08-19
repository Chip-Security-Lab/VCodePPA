//SystemVerilog
module Integrator #(parameter W=8, MAX=255) (
    input clk, rst,
    input [W-1:0] din,
    output reg [W-1:0] dout
);
    reg [W+1:0] accumulator;
    reg [W+1:0] accumulator_buf1, accumulator_buf2;
    reg [W+1:0] acc_for_dout;
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            accumulator <= 0;
            accumulator_buf1 <= 0;
            accumulator_buf2 <= 0;
            acc_for_dout <= 0;
            dout <= 0;
        end
        else begin
            // Update main accumulator
            accumulator <= accumulator + din;
            
            // Buffer stage for fanout reduction
            accumulator_buf1 <= accumulator;
            accumulator_buf2 <= accumulator;
            
            // Dedicated path for dout calculation
            acc_for_dout <= accumulator_buf1;
            
            // Output stage using buffered value
            dout <= (acc_for_dout > MAX) ? MAX : acc_for_dout[W-1:0];
        end
    end
endmodule