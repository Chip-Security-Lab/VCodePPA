module VarShiftAmount #(parameter MAX_SHIFT=4, WIDTH=8) (
    input clk,
    input [MAX_SHIFT-1:0] shift_num,
    input dir, // 0-left 1-right
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
always @(posedge clk) begin
    dout <= dir ? (din >> shift_num) : 
                    (din << shift_num);
end
endmodule
