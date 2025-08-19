module RangeDetector_StateHold #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg state_flag
);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state_flag <= 0;
    else begin
        if(data_in > threshold) state_flag <= 1;
        else if(data_in < threshold) state_flag <= 0;
    end
end
endmodule