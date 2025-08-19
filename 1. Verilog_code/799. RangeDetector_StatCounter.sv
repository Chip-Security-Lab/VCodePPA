module RangeDetector_StatCounter #(
    parameter WIDTH = 8,
    parameter CNT_WIDTH = 16
)(
    input clk, rst_n, clear,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] min_val,
    input [WIDTH-1:0] max_val,
    output reg [CNT_WIDTH-1:0] valid_count
);
wire in_range = (data_in >= min_val) && (data_in <= max_val);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) valid_count <= 0;
    else if(clear) valid_count <= 0;
    else if(in_range) valid_count <= valid_count + 1;
end
endmodule