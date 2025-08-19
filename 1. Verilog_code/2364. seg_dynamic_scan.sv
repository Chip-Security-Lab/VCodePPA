module seg_dynamic_scan #(parameter N=4)(
    input clk,
    input [N*8-1:0] seg_data,
    output reg [3:0] sel,
    output [7:0] seg
);
reg [1:0] cnt;
assign seg = seg_data[cnt*8 +:8];
always @(posedge clk) begin
    cnt <= cnt + 1;
    sel <= ~(1 << cnt);
end
endmodule
