//SystemVerilog
module MuxRecursive #(parameter W=8, N=8) (
    input [W-1:0] din [0:N-1],
    input [$clog2(N)-1:0] sel,
    output [W-1:0] dout
);

    // 实例化选择器子模块
    MuxSelector #(.W(W), .N(N)) selector (
        .din(din),
        .sel(sel),
        .dout(dout)
    );

endmodule

module MuxSelector #(parameter W=8, N=8) (
    input [W-1:0] din [0:N-1],
    input [$clog2(N)-1:0] sel,
    output reg [W-1:0] dout
);

    // 预计算选择信号
    reg [N-1:0] sel_onehot;
    always @(*) begin
        sel_onehot = 0;
        sel_onehot[sel] = 1'b1;
    end

    // 并行数据选择逻辑
    reg [W-1:0] selected_data [0:N-1];
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : data_select
            always @(*) begin
                selected_data[i] = sel_onehot[i] ? din[i] : {W{1'b0}};
            end
        end
    endgenerate

    // 数据输出合并
    always @(*) begin
        dout = 0;
        for (int j = 0; j < N; j = j + 1) begin
            dout = dout | selected_data[j];
        end
    end

endmodule