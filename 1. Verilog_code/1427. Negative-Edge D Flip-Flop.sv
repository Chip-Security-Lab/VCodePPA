module neg_edge_d_ff (
    input wire clk,
    input wire d_in,
    output reg q_out
);
    always @(negedge clk) begin
        q_out <= d_in;
    end
endmodule