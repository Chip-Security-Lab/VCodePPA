//SystemVerilog
// 顶层模块
module MuxTree #(parameter W=4, N=8) (
    input [N-1:0][W-1:0] din,
    input [$clog2(N)-1:0] sel,
    output [W-1:0] dout
);

    wire [W-1:0] stage1_out;
    wire [W-1:0] stage2_out;

    // 第一级多路选择器
    MuxStage1 #(
        .W(W),
        .N(N)
    ) stage1 (
        .din(din),
        .sel(sel[$clog2(N)-1]),
        .dout(stage1_out)
    );

    // 第二级多路选择器
    MuxStage2 #(
        .W(W),
        .N(N)
    ) stage2 (
        .din(stage1_out),
        .sel(sel[$clog2(N)-2:0]),
        .dout(dout)
    );

endmodule

// 第一级多路选择器模块
module MuxStage1 #(parameter W=4, N=8) (
    input [N-1:0][W-1:0] din,
    input sel,
    output reg [W-1:0] dout
);
    always @(*) begin
        if (sel) begin
            dout = din[N/2];
        end else begin
            dout = din[0];
        end
    end
endmodule

// 第二级多路选择器模块
module MuxStage2 #(parameter W=4, N=8) (
    input [W-1:0] din,
    input [$clog2(N)-2:0] sel,
    output reg [W-1:0] dout
);
    always @(*) begin
        dout = din;
    end
endmodule