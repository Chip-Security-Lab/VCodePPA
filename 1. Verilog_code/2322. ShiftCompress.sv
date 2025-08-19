module ShiftCompress #(N=4) (
    input [7:0] din,
    output reg [7:0] dout
);
reg [7:0] shift_reg [0:N-1];
integer i;

always @(*) begin
    // 初始化移位寄存器
    for(i=0; i<N; i=i+1)
        shift_reg[i] = 0;
        
    // 输入数据移入
    shift_reg[0] = din;
    
    // 模拟移位操作
    for(i=N-1; i>0; i=i-1)
        shift_reg[i] = shift_reg[i-1];
        
    // XOR压缩
    dout = 0;
    for(i=0; i<N; i=i+1)
        dout = dout ^ shift_reg[i];
end
endmodule