module EmergencyArbiter (
    input clk, rst,
    input [3:0] req,
    input emergency,
    output reg [3:0] grant
);
always @(posedge clk) begin
    if(emergency)
        grant <= 4'b1000; // 固定选择最后一位
    else
        grant <= req & -req;
end
endmodule
