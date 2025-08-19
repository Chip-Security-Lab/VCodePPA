module sync_adaptive_thresh #(
    parameter DW = 8
)(
    input clk, rst,
    input [DW-1:0] signal_in,
    input [DW-1:0] background,
    input [DW-1:0] sensitivity,
    output reg out_bit
);
    wire [DW-1:0] threshold;
    
    // Threshold adapts to background level
    assign threshold = background + sensitivity;
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            out_bit <= 0;
        else
            out_bit <= (signal_in > threshold) ? 1'b1 : 1'b0;
    end
endmodule