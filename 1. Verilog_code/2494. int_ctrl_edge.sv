module int_ctrl_edge #(
    parameter WIDTH = 8
)(
    input clk, rst,
    input [WIDTH-1:0] async_intr,
    output reg [WIDTH-1:0] synced_intr
);
reg [WIDTH-1:0] intr_ff;
always @(posedge clk or posedge rst) begin
    if(rst) {intr_ff, synced_intr} <= 0;
    else begin
        intr_ff <= async_intr;
        synced_intr <= async_intr & ~intr_ff;
    end
end
endmodule