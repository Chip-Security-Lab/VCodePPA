//SystemVerilog
module d_latch_single (
    input wire d,
    input wire enable,
    output reg q
);
    always @(d or enable) begin
        q = enable ? d : q;
    end
endmodule

module dual_d_latch (
    input wire [1:0] d_in,
    input wire latch_enable,
    output wire [1:0] q_out
);
    d_latch_single latch0 (
        .d(d_in[0]),
        .enable(latch_enable),
        .q(q_out[0])
    );

    d_latch_single latch1 (
        .d(d_in[1]),
        .enable(latch_enable),
        .q(q_out[1])
    );
endmodule