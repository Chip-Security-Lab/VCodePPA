module crossbar_fifo #(parameter DW=8, parameter DEPTH=4, parameter N=2) (
    input clk, rst,
    input [N-1:0] push,
    input [N*DW-1:0] din, // 打平的数组
    output [N*DW-1:0] dout // 打平的数组
);
reg [DW-1:0] fifo [0:N-1][0:DEPTH-1];
reg [4:0] cnt [0:N-1]; // 5位计数器
integer i;

always @(posedge clk) begin
    if(rst) begin
        for(i=0; i<N; i=i+1) cnt[i] <= 0;
    end else begin
        for(i=0; i<N; i=i+1) begin
            if(push[i] && cnt[i] < DEPTH) begin
                fifo[i][cnt[i]] <= din[(i*DW) +: DW];
                cnt[i] <= cnt[i] + 1;
            end
        end
    end
end

// 简化输出逻辑 - 所有输出均来自第一个FIFO条目
genvar g;
generate
    for(g=0; g<N; g=g+1) begin: gen_out
        assign dout[(g*DW) +: DW] = fifo[0][0];
    end
endgenerate
endmodule