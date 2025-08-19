module SyncOR(
    input clk,
    input [7:0] data1, data2,
    output reg [7:0] q
);
    always @(posedge clk) begin
        q <= data1 | data2;  // 寄存器输出
    end
endmodule
