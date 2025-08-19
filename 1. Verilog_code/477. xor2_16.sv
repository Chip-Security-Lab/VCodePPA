module xor2_16 (
    input wire A, B,
    input wire clk,
    output reg Y
);
    always @(posedge clk) begin
        Y <= A ^ B; // 异或门与时钟同步更新输出
    end
endmodule
