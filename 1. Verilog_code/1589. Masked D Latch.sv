module masked_d_latch (
    input wire [7:0] d_in,
    input wire [7:0] mask,
    input wire enable,
    output reg [7:0] q_out
);
    always @* begin
        if (enable)
            q_out = (d_in & mask) | (q_out & ~mask);
    end
endmodule