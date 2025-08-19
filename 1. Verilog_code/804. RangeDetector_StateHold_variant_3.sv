//SystemVerilog
module RangeDetector_StateHold #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg state_flag
);

wire comp_result;
assign comp_result = data_in > threshold;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        state_flag <= 1'b0;
    else 
        state_flag <= comp_result;
end

endmodule