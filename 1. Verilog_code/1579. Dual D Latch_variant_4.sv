//SystemVerilog
module dual_d_latch (
    input wire [1:0] d_in,
    input wire latch_enable,
    output reg [1:0] q_out
);

    // 实例化两个独立的D锁存器
    d_latch #(.WIDTH(1)) latch0 (
        .d_in(d_in[0]),
        .latch_enable(latch_enable),
        .q_out(q_out[0])
    );

    d_latch #(.WIDTH(1)) latch1 (
        .d_in(d_in[1]),
        .latch_enable(latch_enable),
        .q_out(q_out[1])
    );

endmodule

// 参数化的D锁存器子模块
module d_latch #(
    parameter WIDTH = 1
) (
    input wire d_in,
    input wire latch_enable,
    output reg q_out
);

    always @* begin
        if (latch_enable)
            q_out = d_in;
    end

endmodule