module ResetMultiplier(
    input clk, rst,
    input [3:0] x, y,
    output reg [7:0] out
);
    always @(posedge clk or posedge rst) begin
        if(rst) out <= 0;
        else out <= x * y;
    end
endmodule