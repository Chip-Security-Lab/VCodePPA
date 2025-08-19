//SystemVerilog
module MuxRecursive #(parameter W=8, N=8) (
    input [W-1:0] din [0:N-1],
    input [$clog2(N)-1:0] sel,
    output reg [W-1:0] dout
);

    // 预解码逻辑 - 使用独热码编码
    wire [N-1:0] sel_decoded;
    assign sel_decoded = (1'b1 << sel);

    // 数据选择逻辑 - 使用并行选择
    always @(*) begin
        dout = 0;
        for (integer i = 0; i < N; i = i + 1) begin
            dout = dout | (din[i] & {W{sel_decoded[i]}});
        end
    end

endmodule