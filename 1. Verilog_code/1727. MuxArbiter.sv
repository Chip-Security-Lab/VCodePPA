module MuxArbiter #(parameter W=8) (
    input clk,
    input [3:0] req,
    input [3:0][W-1:0] data,
    output reg [W-1:0] grant_data,
    output reg [3:0] grant
);
always @(posedge clk) begin
    if (req[0]) begin grant <= 1; grant_data <= data[0]; end
    else if (req[1]) begin grant <= 2; grant_data <= data[1]; end
    // ...优先级逻辑
end
endmodule