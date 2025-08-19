module dual_d_latch (
    input wire [1:0] d_in,
    input wire latch_enable,
    output reg [1:0] q_out
);
    always @* begin
        if (latch_enable)
            q_out = d_in;
    end
endmodule