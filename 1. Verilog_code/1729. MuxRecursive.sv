module MuxRecursive #(parameter W=8, N=8) (
    input [W-1:0] din [0:N-1], // 修改数组声明
    input [$clog2(N)-1:0] sel,
    output reg [W-1:0] dout
);
    integer i;
    always @(*) begin
        dout = 0;
        for (i = 0; i < N; i = i + 1) begin
            if (sel == i) dout = din[i];
        end
    end
endmodule