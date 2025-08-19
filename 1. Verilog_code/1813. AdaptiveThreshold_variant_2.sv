//SystemVerilog
module AdaptiveThreshold #(parameter W=8) (
    input clk,
    input rst,
    input valid_in,
    input [W-1:0] signal,
    output reg valid_out,
    output reg [W-1:0] threshold
);
    reg [W-1:0] signal_stage1;
    reg valid_stage1;
    reg [W+3:0] sum;
    reg [W+3:0] avg_stage1, avg_stage2;
    
    // Optimized pipeline stage 1 with improved sum calculation
    always @(posedge clk) begin
        if (rst) begin
            sum <= 0;
            signal_stage1 <= 0;
            valid_stage1 <= 0;
        end else if (valid_in) begin
            sum <= sum + signal - sum[W+3:W];
            signal_stage1 <= signal;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Optimized pipeline stage 2 with reduced logic depth
    always @(posedge clk) begin
        if (rst) begin
            avg_stage1 <= 0;
            avg_stage2 <= 0;
            valid_out <= 0;
            threshold <= 0;
        end else if (valid_stage1) begin
            avg_stage1 <= sum[W+3:W];
            avg_stage2 <= avg_stage1;
            threshold <= avg_stage2[W-1:2];  // Direct bit selection instead of shift
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule