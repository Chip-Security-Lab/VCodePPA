module Demux_RingBuffer #(parameter DW=8, N=8) (
    input clk, wr_en,
    input [$clog2(N)-1:0] ptr,
    input [DW-1:0] data_in,
    output reg [N-1:0][DW-1:0] buffer
);
always @(posedge clk) begin
    if(wr_en) begin
        buffer[ptr] <= data_in;
        buffer[(ptr+1)%N] <= 0; // 清空下一位置
    end
end
endmodule
