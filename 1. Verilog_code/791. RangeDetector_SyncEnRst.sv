module RangeDetector_SyncEnRst #(
    parameter WIDTH = 8
)(
    input clk, rst_n, en,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] lower_bound,
    input [WIDTH-1:0] upper_bound,
    output reg out_flag
);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_flag <= 1'b0;
    else if(en) begin
        out_flag <= (data_in >= lower_bound) && 
                   (data_in <= upper_bound);
    end
end
endmodule