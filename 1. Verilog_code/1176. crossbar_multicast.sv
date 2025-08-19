module crossbar_multicast #(parameter DW=8, parameter N=4) (
    input clk, 
    input [N*DW-1:0] din, // 打平的数组
    input [N*N-1:0] dest_mask, // 打平的每个bit对应输出端口
    output reg [N*DW-1:0] dout // 打平的数组
);
integer i, j;
reg [N-1:0] dest_mask_2d [0:N-1];

// 将一维数组转为二维
always @(*) begin
    for(i=0; i<N; i=i+1)
        for(j=0; j<N; j=j+1)
            dest_mask_2d[i][j] = dest_mask[i*N+j];
            
    for(i=0; i<N; i=i+1) begin
        dout[(i*DW) +: DW] = 0;
    end
    
    for(i=0; i<N; i=i+1) begin
        for(j=0; j<N; j=j+1) begin
            if(dest_mask_2d[i][j])
                dout[(j*DW) +: DW] = din[(i*DW) +: DW];
        end
    end
end
endmodule