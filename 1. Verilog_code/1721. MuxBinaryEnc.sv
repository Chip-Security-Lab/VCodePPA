module MuxBinaryEnc #(parameter W=8, N=16) (
    input [N-1:0] req,
    input [W-1:0] data [0:N-1], // 修改数组声明
    output reg [W-1:0] grant_data
);
    integer i;
    always @(*) begin
        grant_data = 0;
        for (i = N-1; i >= 0; i = i - 1)
            if (req[i]) grant_data = data[i];
    end
endmodule