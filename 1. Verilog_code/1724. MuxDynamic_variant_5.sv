//SystemVerilog
module MuxDynamic #(parameter W=8, N=4) (
    input [N*W-1:0] stream,
    input [$clog2(N)-1:0] ch_sel,
    output [W-1:0] active_ch
);

    // 实例化选择器子模块
    ChannelSelector #(
        .W(W),
        .N(N)
    ) channel_selector (
        .stream(stream),
        .ch_sel(ch_sel),
        .active_ch(active_ch)
    );

endmodule

// 通道选择器子模块
module ChannelSelector #(parameter W=8, N=4) (
    input [N*W-1:0] stream,
    input [$clog2(N)-1:0] ch_sel,
    output reg [W-1:0] active_ch
);

    // 通道选择逻辑
    always @(*) begin
        active_ch = stream[ch_sel*W +: W];
    end

endmodule