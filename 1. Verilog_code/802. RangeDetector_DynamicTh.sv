module RangeDetector_DynamicTh #(
    parameter WIDTH = 8
)(
    input clk, wr_en,
    input [WIDTH-1:0] new_low,
    input [WIDTH-1:0] new_high,
    input [WIDTH-1:0] data_in,
    output reg out_flag
);
reg [WIDTH-1:0] current_low, current_high;

always @(posedge clk) begin
    if(wr_en) begin
        current_low <= new_low;
        current_high <= new_high;
    end
    out_flag <= (data_in >= current_low) && (data_in <= current_high);
end
endmodule