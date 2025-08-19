module MuxPriority #(parameter W=8, N=4) (
    input [N-1:0] valid,
    input [W-1:0] data [0:N-1], // 修改数组声明
    output reg [W-1:0] result
);
    integer i;
    always @(*) begin
        result = 0;
        for (i = 0; i < N; i = i + 1) 
            if (valid[i]) result = data[i];
    end
endmodule