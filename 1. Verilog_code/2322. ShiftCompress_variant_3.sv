//SystemVerilog
module ShiftCompress #(
    parameter N = 4
) (
    input [7:0] din,
    output reg [7:0] dout
);
    // 桶形移位器实现
    wire [7:0] shift_data [0:N-1];
    reg [7:0] compressed_result;
    integer i;
    
    // 桶形移位器结构 - 使用固定移位和多路复用代替变量移位
    assign shift_data[0] = din;
    assign shift_data[1] = {1'b0, din[7:1]};
    assign shift_data[2] = {2'b0, din[7:2]};
    assign shift_data[3] = {3'b0, din[7:3]};
    
    always @(*) begin
        // 并行压缩操作
        compressed_result = 8'b0;
        for (i = 0; i < N; i = i + 1) begin
            compressed_result = compressed_result ^ shift_data[i];
        end
        
        // 赋值输出
        dout = compressed_result;
    end
endmodule